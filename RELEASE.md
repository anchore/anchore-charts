# Releasing Anchore Helm Charts

In our Helm chart release strategy we have developed a pipeline to accommodate current and non-current versions of our enterprise software. To accomplish this, we are utilizing multiple release branches with distinct release pipelines. The `release-<chart_name>-<non-current_chart_version>` branching strategy involves a release process that is dedicated to the ongoing support of non-current, but still supported, Enterprise platform versions. The `main` branch is dedicated to the ongoing support of current & future Enterprise platform versions.

All release processes are controlled via CI using GitHub actions. Charts are linted and released using the official Helm [chart-testing](https://github.com/helm/chart-testing) and [chart-releaser](https://github.com/helm/chart-releaser) tools.

## Release Documentation

*Note: Ensure that Helm and GitHub credentials are configured appropriately for successful execution of the release process.*

### Release Process for Current Charts

1. **Create a Branch:**
   - Start by creating a new branch for your changes off of the `main` branch.

     ```bash
     git checkout main
     git pull origin main
     git checkout -b feature-update
     ```

2. **Make and Commit Changes:**
   - Implement your changes in the branch.
   - Ensure Helm unit tests are updated and passing.
   - Commit your changes.
   - Push your branch to GitHub

     ```bash
     git commit -sm "feat: implement updates"
     helm unittest .
     git push origin feature-update
     ```

3. **Create Pull Request:**
   - Open a pull request against the `main` branch on GitHub.
   - Provide a descriptive title and description for the changes.

4. **GitHub Actions and Chart Releasing:**
   - Once the pull request is merged, GitHub Actions will automatically trigger the `chart-releaser-action`.
   - This action will create the Helm release for the updated chart.

### Release Process for Non-Current Charts

1. **Branching:**
   - Create a new release branch off the latest v1.x.x tag named `release-enterprise-1.x.x`.
   - Push the release branch to GitHub.
   - Create a new branch off of the `release-enterprise-1.x.x` branch using a meaningful name for your changes.
   - Example:

     ```bash
     git checkout v1.0.0
     git checkout -b release-enterprise-1.x.x
     git push origin release-enterprise-1.x.x
     git checkout -b enterprise-1.x.x-feature-xyz
     ```

2. **Make and Commit Changes:**
   - Make necessary changes in your branch.
   - Ensure that any affected Helm unit tests are updated and passing.
   - Commit your changes.
   - Example:

     ```bash
     git commit -sm "feat: update something"
     helm unittest .
     git push origin enterprise-1.x.x-feature-xyz
     ```

3. **Create Pull Request:**
   - Open a pull request against the `release-enterprise-1.x.x` branch on GitHub.
   - Provide a concise and informative title and description for your changes.

4. **GitHub Actions and Chart Releasing:**
   - Upon merging the pull request, a GitHub Action (`chart-releaser-action`) will be triggered automatically.
   - The action will create the Helm release for the updated chart.

5. **Managing GitHub Releases Page:**
   - Navigate to the GitHub Releases page.
   - Locate the latest release associated with the `enterprise-1.x.x` branch and make sure its not marked as latest. If it is, manually mark the actual latest release as 'latest.'
   - Note: This step is crucial to distinguish the actual latest release from patch updates.

## Chart Distribution

Our Helm charts are distributed via GitHub Pages and managed using the `gh-pages` branch in this repository. The chart repository is available at <https://charts.anchore.io>. The `chart-releaser-action` will automatically perform the following actions when a PR is merged to the `main` OR `release-*` branches:

- Create a GitHub tag & release for all changed charts, using `<chart_name>-<chart_version>` as the tag name.
- Package the chart and upload the created tarball to the corresponding GitHub release page.
- Updates the `chart.yaml` file in the `gh-pages` branch with the latest chart version & package location.
