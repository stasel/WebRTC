import os
import json
import requests
import re
import subprocess
from datetime import datetime, timedelta
from dataclasses import dataclass

GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
GITHUB_REPO = os.environ.get("GITHUB_REPOSITORY", "stasel/WebRTC")
INITIAL_WEBRTC_MILESTONE = os.environ.get("INITIAL_WEBRTC_MILESTONE")
VERSION_RE = re.compile(r"^(\d+)\.\d+\.\d+$")

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
    dsym: str

def githubHeaders():
    headers = {'accept': 'application/vnd.github.v3+json'}
    if GITHUB_TOKEN:
        headers['Authorization'] = f"token {GITHUB_TOKEN}"
    return headers

def milestoneFromVersion(value):
    if not value:
        return None

    match = VERSION_RE.match(value.strip())
    if not match:
        return None

    return int(match.group(1))

def localMetadataMilestones():
    milestones = []

    try:
        with open("WebRTC.json", 'r') as f:
            for version in json.loads(f.read()).keys():
                milestone = milestoneFromVersion(version)
                if milestone:
                    milestones.append(milestone)
    except (FileNotFoundError, json.JSONDecodeError, OSError) as e:
        print(f"Warning: failed to read WebRTC.json: {e}")

    for filename in ["Package.swift", "WebRTC-lib.podspec"]:
        try:
            with open(filename, 'r') as f:
                for match in re.finditer(
                    r"/download/([0-9]+\.[0-9]+\.[0-9]+)/",
                    f.read()
                ):
                    milestone = milestoneFromVersion(match.group(1))
                    if milestone:
                        milestones.append(milestone)
        except OSError as e:
            print(f"Warning: failed to read {filename}: {e}")

    try:
        tags = subprocess.check_output(
            ["git", "tag", "--list"],
            text=True
        )
        for tag in tags.splitlines():
            milestone = milestoneFromVersion(tag)
            if milestone:
                milestones.append(milestone)
    except (OSError, subprocess.CalledProcessError) as e:
        print(f"Warning: failed to read git tags: {e}")

    return milestones

def currentMilestoneFromMetadata():
    milestones = localMetadataMilestones()
    if milestones:
        milestone = max(milestones)
        print(f"Latest local metadata release: version {milestone}")
        return milestone

    if INITIAL_WEBRTC_MILESTONE:
        try:
            milestone = int(INITIAL_WEBRTC_MILESTONE)
            print(f"Latest release fallback: version {milestone}")
            return milestone
        except ValueError:
            print(
                "Warning: INITIAL_WEBRTC_MILESTONE must be an integer, "
                f"got {INITIAL_WEBRTC_MILESTONE}"
            )

    print("❌ No GitHub releases or local metadata versions were found")
    os._exit(os.EX_SOFTWARE)

def currentMilestoneFromGitHubReleases():
    try:
        response = requests.get(
            f"https://api.github.com/repos/{GITHUB_REPO}/releases",
            headers=githubHeaders()
        )
        response.raise_for_status()
        releases = response.json()
    except requests.RequestException as e:
        print(
            f"Warning: failed to fetch GitHub releases for {GITHUB_REPO}: "
            f"{e}; using repository metadata instead"
        )
        return currentMilestoneFromMetadata()

    if not isinstance(releases, list):
        print(f"❌ Unexpected GitHub releases response: {releases}")
        os._exit(os.EX_SOFTWARE)

    publishedReleases = [
        release for release in releases
        if not release.get("draft") and release.get("published_at")
    ]
    releaseVersions = [
        milestoneFromVersion(release.get("tag_name", ""))
        for release in publishedReleases
    ]
    releaseVersions = [version for version in releaseVersions if version]

    if not releaseVersions:
        print(
            f"Warning: no published GitHub releases found for {GITHUB_REPO}; "
            "using repository metadata instead"
        )
        return currentMilestoneFromMetadata()

    latestReleaseVersion = max(releaseVersions)
    latestRelease = next(
        release for release in publishedReleases
        if milestoneFromVersion(release.get("tag_name", ""))
        == latestReleaseVersion
    )
    latestReleaseDate = datetime.fromisoformat(
        latestRelease["published_at"].replace("Z", "")
    )
    print(
        f"Latest release: version {latestReleaseVersion}, "
        f"date: {latestReleaseDate}"
    )
    return latestReleaseVersion

def getStableMilestone():
    """Find the current stable milestone from the Chromium Dashboard."""
    try:
        response = requests.get("https://chromiumdash.appspot.com/fetch_milestones")
        response.raise_for_status()
        milestones = response.json()
        stable = [m for m in milestones if m.get("schedule_phase") == "stable"]
        if stable:
            return int(max(stable, key=lambda m: m["milestone"])["milestone"])
        print("Warning: no milestone with schedule_phase 'stable' found")
    except (requests.RequestException, KeyError, ValueError, TypeError) as e:
        print(f"Warning: failed to fetch stable milestone: {e}")
    return None

def getNextRelease():
    # Get current version
    latestReleaseVersion = currentMilestoneFromGitHubReleases()

    # Get the current stable milestone
    stableMilestone = getStableMilestone()
    if not stableMilestone:
        print("❌ Could not determine current stable milestone")
        os._exit(os.EX_SOFTWARE)

    nextReleaseVersion = max(latestReleaseVersion + 1, stableMilestone)
    if nextReleaseVersion > latestReleaseVersion + 1:
        print(f"Current stable milestone is M{stableMilestone}, skipping ahead from M{latestReleaseVersion + 1}")

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
    os.environ["BRANCH"] = branch
    os.environ["IOS"] = "true"
    os.environ["MACOS"] = "true"
    os.environ["MAC_CATALYST"] = "true"

    return os.system('sh scripts/build.sh') == 0

def getBuildMetadata(outputDir):
    with open(f"{outputDir}/metadata.json", 'r') as f:
        jsonData = json.loads(f.read())
        return BuildMetadata(filename = jsonData['file'], checksum = jsonData['checksum'], commit = jsonData['commit'], branch = jsonData['branch'], dsym = jsonData['dsym'])

def createReleaseDraft(release, buildMetadata):
    tag_name = f'{release.version}.0.0'
    body = f"Release notes: https://webrtc.googlesource.com/src.git/+log/refs/{buildMetadata.branch}/\n"
    body += f"WebRTC Branch: [{buildMetadata.branch}](https://chromium.googlesource.com/external/webrtc/+log/{buildMetadata.branch})\n"
    body += f"WebRTC Commit: `{buildMetadata.commit}`\n"
    body += f"SHA 256 checksum: `{buildMetadata.checksum}`"

    fields = { 
        'name': f'M{release.version}',
        'tag_name': tag_name,
        'draft': True,
        'body': body
    }

    matchingReleases = releasesByTag(tag_name)
    publishedReleases = [
        release for release in matchingReleases
        if not release.get("draft")
    ]
    if publishedReleases:
        print(
            f"❌ Release {tag_name} already exists and is published; "
            "refusing to modify published release assets"
        )
        return {}

    existingRelease = newestRelease(matchingReleases)
    if existingRelease:
        print(f"Warning: release draft for {tag_name} already exists; reusing it")
        patchResponse = requests.patch(
            existingRelease["url"],
            json=fields,
            headers=githubHeaders()
        )
        if patchResponse.ok:
            return patchResponse.json()
        print(
            "Warning: failed updating existing release draft: "
            f"{patchResponse.status_code} {patchResponse.text}"
        )
        return existingRelease

    response = requests.post(
        f"https://api.github.com/repos/{GITHUB_REPO}/releases",
        json=fields,
        headers=githubHeaders()
    )
    if response.status_code == requests.codes.created:
        return response.json()

    print(
        f"❌ Failed creating release draft: "
        f"{response.status_code} {response.text}"
    )
    return {}

def newestRelease(releases):
    if not releases:
        return None

    releases.sort(
        key=lambda release: release.get("created_at", ""),
        reverse=True
    )
    return releases[0]

def releasesByTag(tag_name):
    page = 1
    matchingReleases = []
    while True:
        response = requests.get(
            f"https://api.github.com/repos/{GITHUB_REPO}/releases",
            params={"per_page": 100, "page": page},
            headers=githubHeaders()
        )
        if not response.ok:
            print(
                f"Warning: failed listing releases: "
                f"{response.status_code} {response.text}"
            )
            return None

        releases = response.json()
        if not releases:
            break

        for release in releases:
            if release.get("tag_name") == tag_name:
                matchingReleases.append(release)

        page += 1

    if len(matchingReleases) > 1:
        print(
            f"Warning: found {len(matchingReleases)} releases for {tag_name}; "
            "checking whether one can be reused"
        )
    return matchingReleases

def deleteExistingReleaseAsset(release, assetName):
    response = requests.get(release["assets_url"], headers=githubHeaders())
    if not response.ok:
        print(
            f"Warning: failed listing release assets: "
            f"{response.status_code} {response.text}"
        )
        return False

    for asset in response.json():
        if asset.get("name") != assetName:
            continue

        deleteResponse = requests.delete(asset["url"], headers=githubHeaders())
        if deleteResponse.status_code not in (requests.codes.no_content, 404):
            print(
                f"Warning: failed deleting existing asset {assetName}: "
                f"{deleteResponse.status_code} {deleteResponse.text}"
            )
            return False

    return True

def uploadReleaseAsset(release, assetLocalPath, assetName):
    if not deleteExistingReleaseAsset(release, assetName):
        return False

    url = release["upload_url"].replace(u'{?name,label}','')
    size = os.stat(assetLocalPath).st_size
    params = {'name': assetName}
    headers = githubHeaders()
    headers['Content-Length'] = str(size)
    headers['Content-Type'] = 'Application/zip'
    with open(assetLocalPath, 'rb') as fileToUpload:
        response = requests.post(
            url,
            params = params,
            data = fileToUpload,
            headers = headers
        )
    success = response.status_code == requests.codes.created
    if not success:
        print(
            f"❌ Failed uploading release asset {assetName}: "
            f"{response.status_code} {response.text}"
        )
    return success

def createPullRequest(release, head):
    owner = GITHUB_REPO.split("/")[0]
    body = { 
        'title': f'Release M{release.version}',
        'head': head,
        'base': 'latest',
        'body': f'Updated files for release M{release.version}.'
    }
    response = requests.post(
        f"https://api.github.com/repos/{GITHUB_REPO}/pulls",
        json=body,
        headers=githubHeaders()
    )
    success = response.status_code == requests.codes.created
    if success:
        return True

    existingPr = pullRequestForBranch(f'{owner}:{head}')
    if existingPr:
        print(f"Warning: release pull request already exists: {existingPr['html_url']}")
        return True

    print(
        f"❌ Failed creating pull request: "
        f"{response.status_code} {response.text}"
    )
    return False

def pullRequestForBranch(head):
    response = requests.get(
        f"https://api.github.com/repos/{GITHUB_REPO}/pulls",
        params={"state": "open", "head": head, "base": "latest"},
        headers=githubHeaders()
    )
    if not response.ok:
        print(
            f"Warning: failed checking existing pull requests: "
            f"{response.status_code} {response.text}"
        )
        return None

    pullRequests = response.json()
    if pullRequests:
        return pullRequests[0]

    return None

def runGit(args):
    subprocess.run(["git", *args], check=True)

def remoteBranchExists(branch):
    return subprocess.run(
        ["git", "ls-remote", "--exit-code", "--heads", "origin", branch],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    ).returncode == 0

def pushReleaseBranch(branch):
    if remoteBranchExists(branch):
        runGit(["fetch", "origin", f"{branch}:refs/remotes/origin/{branch}"])
        runGit(["push", "--force-with-lease", "origin", branch])
    else:
        runGit(["push", "origin", branch])

def commitReleaseMetadata(version):
    runGit(["add", "Package.swift", "WebRTC-lib.podspec", "README.md", "WebRTC.json"])
    if subprocess.run(["git", "diff", "--cached", "--quiet"]).returncode == 0:
        print(f"Warning: release metadata for M{version} is already current")
        return

    runGit(["commit", "-m", f"Updated files for release M{version}"])

def configureGitAuthor():
    runGit(["config", "user.name", "github-actions[bot]"])
    runGit([
        "config",
        "user.email",
        "41898282+github-actions[bot]@users.noreply.github.com"
    ])

def checkoutReleaseBranch(branch):
    runGit(["checkout", "-B", branch])

def replaceInFile(filename, replacements):
    with open(filename, 'r') as f:
        content = f.read()

    for pattern, replacement in replacements:
        content = re.sub(pattern, replacement, content)

    with open(filename, 'w') as f:
        f.write(content)

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
    outputDir="./out"
    buildMetadata = getBuildMetadata(outputDir)
    print(buildMetadata)

    # Create new release draft
    print("➡️ Creating new release draft...")
    githubReleaseDraft = createReleaseDraft(nextRelease ,buildMetadata)
    if 'upload_url' not in githubReleaseDraft:
        print(f"❌ Failed creating release draft: {githubReleaseDraft}")
        os._exit(os.EX_SOFTWARE)

    # Upload asset to github
    print("➡️ Uploading assets to github...")
    uploadResultFramework = uploadReleaseAsset(
        githubReleaseDraft,
        os.path.join(outputDir, buildMetadata.filename),
        f"WebRTC-M{nextRelease.version}.xcframework.zip"
    )

    uploadResultdSYM = uploadReleaseAsset(
        githubReleaseDraft,
        os.path.join(outputDir, buildMetadata.dsym), 
        f"WebRTC-M{nextRelease.version}-dSYM.zip"
    )

    if not uploadResultFramework or not uploadResultdSYM:
        print("❌ Failed uploading asset to github")
        os._exit(os.EX_SOFTWARE)

    print(f"✅ Successfully created new draft release in github: {githubReleaseDraft['url']}")

    # Create new branch with code changes
    print("➡️ Creating local branch...")
    releaseBranch = f'release-M{nextRelease.version}'
    configureGitAuthor()
    checkoutReleaseBranch(releaseBranch)

    # Change code
    print("➡️ Applying code changes...")
    nextVersion = f"{nextRelease.version}.0.0"
    releaseAssetURL = (
        f"https://github.com/{GITHUB_REPO}/releases/download/"
        f"{nextVersion}/WebRTC-M{nextRelease.version}.xcframework.zip"
    )
    releaseURLPattern = (
        r"https://github\.com/[^\"']+/releases/download/"
        r"[0-9]+\.[0-9]+\.[0-9]+/WebRTC-M[0-9]+(?:\.[0-9]+)?"
        r"\.xcframework\.zip"
    )
    replaceInFile("Package.swift", [
        (releaseURLPattern, releaseAssetURL),
        (r'checksum: "[0-9a-f]+"', f'checksum: "{buildMetadata.checksum}"'),
    ])
    replaceInFile("WebRTC-lib.podspec", [
        (releaseURLPattern, releaseAssetURL),
        (
            r'spec\.version\s+= "[0-9]+\.[0-9]+\.[0-9]+"',
            f'spec.version      = "{nextVersion}"'
        ),
        (r'checksum: "[0-9a-f]+"', f'checksum: "{buildMetadata.checksum}"'),
    ])
    replaceInFile("README.md", [
        (
            r'\.upToNextMajor\("[0-9]+\.[0-9]+\.[0-9]+',
            f'.upToNextMajor("{nextVersion}'
        ),
    ])
    cartageFile = open("WebRTC.json", 'r')

    cartageJSON = json.loads(cartageFile.read())
    cartageJSON[nextVersion] = releaseAssetURL
    cartageFile.close()
    cartageJSONWrite = open("WebRTC.json", 'w')
    cartageJSONWrite.write(json.dumps(cartageJSON, indent=4, sort_keys=True))
    cartageJSONWrite.close()


    # Commit and push
    print("➡️ Committing and pushing code to remote...")
    commitReleaseMetadata(nextRelease.version)
    pushReleaseBranch(releaseBranch)

    # Create PR
    print("➡️ Creating pull request...")
    prResult = createPullRequest(nextRelease, releaseBranch)
    if not prResult:
        print("❌ Failed creating pull request in github")
        os._exit(os.EX_SOFTWARE)

    print(f"✅ Done")
