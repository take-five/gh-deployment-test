# validate-k8s-deployment.rb

A CLI tool that checks that given Kubernetes Deployment manifests originate from
expected GitHub deployments.

This tool looks at a given Kubernetes `apps/v1` API Deployment manifest file,
looks for a set of `github.com/` prefixed metadata annotations, and verifies
that the Deployment resource has a corresponding GitHub Deployment record for
given repo, environment and commit sha. Environment value to check for is taken
as a configuration option to the tool.

## Install

1. Make sure to have Ruby 2.6 installed
2. Clone this repository: `git clone git@github.com:take-five/gh-deployment-test.git`
3. Run `bundle install`

## Set up GitHub access

1. [Generate GitHub personal access token](https://github.com/settings/tokens/new?scopes=repo) with
   full access to the target repository.
2. Export access token as environment variable:
   ```bash
   export GITHUB_ACCESS_TOKEN="..."
   ```

### Usage

1. Create a test deployment in the target repository:
   ```bash
   ./create-deployment.rb -e staging --ref=main take-five/gh-deployment-test
   ```
2. It will print out created deployment details:
   ```
   Deployment created:
   - id: 290760338
   - url: https://api.github.com/repos/take-five/gh-deployment-test/deployments/290760338
   - sha: d00f1036be6156f8bd938205c062a31759b9ab00
   - environment: staging
   ```
3. Add deployment SHA and repository name to Kubernetes Deployment manifest:
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: nginx-deployment
     labels:
       app: nginx
     annotations:
       github.com/repo: take-five/gh-deployment-test
       github.com/sha: d00f1036be6156f8bd938205c062a31759b9ab00
   ```
4. Verify Kubernetes Deployment:
   ```
   ./validate-k8s-deployment.rb -e staging manifest.yml
   ```

For easier testing `./create-deployment.rb` can inject the repository name and deployment SHA
into existing Kubernetes Deployment manifest. The output of that program can be fed into
`./validate-k8s-deployment.rb`:

```bash
export GITHUB_REPO=take-five/gh-deployment-test
export GITHUB_ENV=staging

./create-deployment.rb "$GITHUB_REPO" -m deployment-example.yaml |
./validate-k8s-deployment.rb -e "$GITHUB_ENV"
```
