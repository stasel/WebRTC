import os
import json
import requests
from datetime import datetime, timedelta
from dataclasses import dataclass
import telegram

GITHUB_TOKEN=os.environ.get("GITHUB_TOKEN")
TELEGRAM_TOKEN=os.environ.get("TELEGRAM_TOKEN")
TELEGRAM_CHAT_ID=os.environ.get("TELEGRAM_CHAT_ID")

@dataclass
class NextReleaseResult:
    version: int
    releaseDate: datetime
    branch: str

@dataclass
class BuildMetadata:
    filename: str
    checksum: str
    commit: str
    branch: str

def getNextRelease():
    # Get current version
    releases = requests.get("https://api.github.com/repos/stasel/WebRTC/releases", headers={'Authorization': f"token {GITHUB_TOKEN}"}).json()
    print(releases)
    latestReleaseVersion = int(releases[0]["tag_name"].split(".")[0])
    latestReleaseDate = datetime.fromisoformat(releases[0]["published_at"].replace("Z", ""))
    print(f"Latest release: version {latestReleaseVersion}, date: {latestReleaseDate}")

    # Get next version
    nextReleaseVersion = latestReleaseVersion + 1
    milestones = requests.get(f"https://chromiumdash.appspot.com/fetch_milestone_schedule?mstone={nextReleaseVersion}").json()
    nextReleaseDate = datetime.fromisoformat(milestones["mstones"][0]["stable_date"])
    print(f"Next release:   version {nextReleaseVersion}, date: {nextReleaseDate}")

    # Get next version branch
    releases = requests.get(f"https://chromiumdash.appspot.com/fetch_milestones?mstone={nextReleaseVersion}").json()
    nextReleaseBranch = "branch-heads/" + releases[0]["webrtc_branch"]

    return NextReleaseResult(version = nextReleaseVersion, releaseDate = nextReleaseDate, branch = nextReleaseBranch)

def isReleaseAvailable(release):
    return datetime.today() >= (release.releaseDate + timedelta(days=1))

def buildWebRTC(branch):
    os.environ["BUILD_VP9"] = "true"
    os.environ["BRANCH"] = branch
    os.environ["IOS"] = "true"
    os.environ["MACOS"] = "true"
    os.environ["MAC_CATALYST"] = "true"

    return os.system('sh scripts/build.sh') == 0

def getBuildMetadata(outputDir):
    with open(f"{outputDir}/metadata.json", 'r') as f:
        jsonData = json.loads(f.read())
        return BuildMetadata(filename = jsonData['file'], checksum = jsonData['checksum'], commit = jsonData['commit'], branch = jsonData['branch'])

def createReleaseDraft(release, buildMetadata):
    body = "Release notes: N/A\n"
    body += f"WebRTC Branch: [{buildMetadata.branch}](https://chromium.googlesource.com/external/webrtc/+log/{buildMetadata.branch})\n"
    body += f"WebRTC Commit: `{buildMetadata.commit}`\n"
    body += f"SHA 256 checksum: `{buildMetadata.checksum}`"

    fields = { 
        'name': f'M{release.version}',
        'tag_name': f'{release.version}.0.0',
        'draft': True,
        'body': body
    }
    headers = {'accept': 'application/vnd.github.v3+json', 'Authorization': f'token {GITHUB_TOKEN}'}
    return requests.post("https://api.github.com/repos/stasel/WebRTC/releases", json = fields, headers = headers).json()

def uploadReleaseAsset(url, assetLocalPath, assetName):
    url = url.replace(u'{?name,label}','')
    fileToUpload = open(assetLocalPath, 'rb')  
    size = os.stat(assetLocalPath).st_size
    params = {'name': assetName}
    headers = {'Authorization': f'token {GITHUB_TOKEN}', 'Content-Length': str(size), 'Content-Type': 'Application/zip'}
    response = requests.post(url, params = params, data = fileToUpload, headers = headers)
    success = response.status_code == requests.codes.created
    if not success:
        print(response)
    return success

def createPullRequest(release, head):
    headers = {'accept': 'application/vnd.github.v3+json', 'Authorization': f'token {GITHUB_TOKEN}'}
    body = { 
        'title': f'Release M{release.version}',
        'head': head,
        'base': 'latest',
        'body': 'Created by an automated sotfware 🤖'
    }
    response = requests.post("https://api.github.com/repos/stasel/WebRTC/pulls", json = body, headers = headers)
    success = response.status_code == requests.codes.created
    if not success:
        print(response)
    return success

if __name__ == "__main__":
    if not GITHUB_TOKEN:
        print("❌ GITHUB_TOKEN environment variable is not provided")
        os._exit(os.EX_SOFTWARE)

    # Get next release details
    print("➡️ Fetching next release...")
    nextRelease = getNextRelease()

    # Check if it is time for a new reelease
    if not isReleaseAvailable(nextRelease):
        print("ℹ️  Next version is not out yet. Skipping build")
        os._exit(os.EX_OK)

    print(f"✅ {nextRelease}\n")
    print("✅ New Version is available to build")

    # Build WebRTC Frameworks
    print("➡️ Building WebRTC Library...")
    buildSuccess = buildWebRTC(nextRelease.branch)
    if not buildSuccess:
        print("❌ WebRTC Build Failed")
        os._exit(os.EX_SOFTWARE)
        
    print("✅ WebRTC build successful\n")

    # Get metadata build file - it has all the information needed about the build
    outputDir="src/out"
    buildMetadata = getBuildMetadata(outputDir)
    print(buildMetadata)

    # Create new release draft
    print("➡️ Creating new release draft...")
    githubReleaseDraft = createReleaseDraft(nextRelease ,buildMetadata)

    # Upload asset to github
    print("➡️ Uploading asset to github...")
    assetName = f"WebRTC-M{nextRelease.version}.xcframework.zip"
    assetPath = os.path.join(outputDir, buildMetadata.filename)
    uploadURL = githubReleaseDraft['upload_url']
    uploadResult = uploadReleaseAsset(uploadURL, assetPath, assetName)

    if not uploadResult:
        print("❌ Failed uploading asset to github")
        os._exit(os.EX_SOFTWARE)

    print(f"✅ Successfully created new draft release in github: {githubReleaseDraft['url']}")

    # Create new branch with code changes
    print("➡️ Creating local branch...")
    releaseBranch = f'release-M{nextRelease.version}'
    os.system(f'git checkout -b {releaseBranch}')

    # Change code
    print("➡️ Applying code changes...")
    os.system(f"sed -i '' -E 's/[0-9]+.0.0\/WebRTC-M[0-9]+/{nextRelease.version}.0.0\/WebRTC-M{nextRelease.version}/g' Package.swift WebRTC-lib.podspec")
    os.system(f"sed -i '' -E 's/checksum: \"[0-9a-f]+\"/checksum: \"{buildMetadata.checksum}\"/g' Package.swift WebRTC-lib.podspec ")
    os.system(f"sed -i '' -E 's/.upToNextMajor\\(\"[0-9]+.0.0/.upToNextMajor\\(\"{nextRelease.version}.0.0/g' README.md")
    os.system(f"sed -i '' -E 's/spec.version      = \"[0-9]+.0.0\"/spec.version      = \"{nextRelease.version}.0.0\"/g' WebRTC-lib.podspec")
    cartageFile = open("WebRTC.json", 'r')

    cartageJSON = json.loads(cartageFile.read())
    cartageJSON[f'{nextRelease.version}.0.0'] = f'https://github.com/stasel/WebRTC/releases/download/{nextRelease.version}.0.0/WebRTC-M{nextRelease.version}.xcframework.zip'
    cartageFile.close()
    cartageJSONWrite = open("WebRTC.json", 'w')
    cartageJSONWrite.write(json.dumps(cartageJSON, indent=4, sort_keys=True))
    cartageJSONWrite.close()


    # Commit and push
    print("➡️ Commiting and pushing code to remote...")
    os.system(f'git add .')
    os.system(f'git commit -m "Updated files for release M{nextRelease.version}"')
    os.system(f'git push origin {releaseBranch}')

    # Create PR
    print("➡️ Creating pull request...")
    prResult = createPullRequest(nextRelease, releaseBranch)
    if not prResult:
        print("❌ Failed creating pull request in github")
        os._exit(os.EX_SOFTWARE)

    # Notify about the new release via Telegram bot
    if TELEGRAM_TOKEN and TELEGRAM_CHAT_ID:
        print("➡️ Sending Telegram notification...")
        bot = telegram.Bot(token=TELEGRAM_TOKEN)
        message = f"New WebRTC Release M{nextRelease.version} is now available.\nCheck the PR here: https://github.com/stasel/WebRTC/pulls"
        bot.send_message(chat_id=TELEGRAM_CHAT_ID, text=message)

    print(f"✅ Done")
