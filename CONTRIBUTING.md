# Contributing to Rokwire Platform

First of all, thanks for considering contributing to the Rokwire Platform. We look forward to hearing and learning from you and receiving your contribution. We have put together the following guidelines to help you navigate the contribution process and to outline expectations.

## Code of Conduct

The [Rokwire Code of Conduct](CODE_OF_CONDUCT.md) governs this project and everyone participating in it. By participating in this project, we expect you to uphold this code. Please report unacceptable behavior to rokwire@illinois.edu.

## How to Contribute

There are different ways you can contribute to the Rokwire Platform. You can start by searching the existing issues and pull requests in the Rokwire GitHub repositories. It will help to see if what you are planning to contribute is already under discussion. As described below, we welcome various kinds of contributions, such as Reporting Bugs, Requesting Features/Enhancements, Contributing Code.

## Reporting Bugs/Accessibility/Usability Issues

If you find any bugs, accessibility or usability issues please report them using the appropriate [issue templates](https://github.com/rokwire/illinois-app/issues/new/choose). Please make sure that it’s not a duplicate of an existing issue by searching the [issues list](https://github.com/rokwire/illinois-app/issues). Please provide as many details as possible to help the contributors who, like you, will be working on it in the future.

## Requesting Features/Enhancements

We are always on the lookout for new ideas and feature requests. Please share your thoughts about a new feature or enhancement by submitting a [Feature Request](https://github.com/rokwire/illinois-app/issues/new?assignees=pmarkhennessy&labels=Type%3A+Feature+Request&template=feature_request.md&title=%5BFEATURE%5D+). Please make sure that this is not a duplicate of an existing feature request by searching the [issues list](https://github.com/rokwire/illinois-app/issues). Here also, please share as many details as possible for future discussion.

## Contributing Code

We are excited that you may be interested in contributing code to the Rokwire Platform. To maintain standards of programming and to keep things manageable, we request that you follow the workflow shared below. Any contributor who is not an employee of the University of Illinois whose official duties include contributing to the Rokwire software, or who is not paid by the Rokwire project, needs to sign the [Rokwire Contributors License Agreement (CLA)](https://rokwire.org/rokwire_cla) before their contribution can be accepted. If you belong to this group, please complete and sign the CLA and then scan and email a PDF file of the CLA to rokwire@illinois.edu. If necessary, you can send an original signed agreement to Rokwire, University of Illinois, 331 Grainger Engineering Library, 1301 W. Springfield Avenue, MC-274, Urbana, Illinois 61801.

### Development Workflow
 
1. Create a [GitHub account](https://github.com/join), if you don’t already have one.
2. Start the development workflow either by [creating a new issue](https://docs.github.com/en/free-pro-team@latest/github/managing-your-work-on-github/creating-an-issue) or by starting from an already existing issue in the repository. We expect that each contribution, whether major or minor, always starts from an issue. An issue can be either a bug report, accessibility report, usability report, or a feature request. When creating a new GitHub issue, please make sure to include as many details as possible. If starting from an existing GitHub issue, please make sure that you understand it clearly, and if not, please share your questions/comments in the issue to get things clarified before you start writing code. When working on a new feature request, it will be a good idea to have discussions with the Rokwire Open Source community through GitHub issues, before starting design and development.
3. [Create a fork of the repository and clone](https://docs.github.com/en/free-pro-team@latest/github/getting-started-with-github/fork-a-repo) it to your development machine.
4. [Create a new branch](https://docs.github.com/en/free-pro-team@latest/github/collaborating-with-issues-and-pull-requests/creating-and-deleting-branches-within-your-repository#creating-a-branch) from the `develop` branch. Please use the following naming convention for naming branches: `<issue number>-<short-description-separated-by-hyphens>`. For example, `201-add-maps-for-event-locations`.
5. Implement the code changes on your branch. Please make sure to update the [CHANGELOG](CHANGELOG.md) and relevant documentation as needed.
6. From your branch in the forked repository, make a pull request against the develop branch in the root repository. Please follow the instructions and provide more details about your pull request using the [pull request template](.github/pull_request_template.md).
7. Please link your pull request to the GitHub issue that you are trying to implement or fix. Please see the relevant [GitHub documentation](https://docs.github.com/en/github/managing-your-work-on-github/linking-a-pull-request-to-an-issue) on this.
8. When the pull request is created, the code repository maintainer(s) gets added as reviewers automatically. Work with the maintainer(s) to get your change reviewed. The maintainer(s) may also invite other experts or developers as reviewers.
9. After your pull request is reviewed and approved by the maintainer(s), a maintainer will [merge your branch](https://docs.github.com/en/free-pro-team@latest/github/collaborating-with-issues-and-pull-requests/merging-a-pull-request#merging-a-pull-request-on-github) to the develop branch using a squash commit.
10. After your branch has been merged to the remote develop branch, pull the latest code from the remote repository to your forked repository to view your change in your development environment.
11. At this point, you may want to [delete your local branch](https://docs.github.com/en/free-pro-team@latest/github/collaborating-with-issues-and-pull-requests/creating-and-deleting-branches-within-your-repository#deleting-a-branch) in your forked repository.

### Code Reviews

Each repository will have at least one maintainer who will be responsible for reviewing the incoming pull request. In certain situations, other contributors may also be brought in as reviewers by the maintainer. After a pull request gets successfully reviewed, the incoming branch is merged to the develop branch. To keep the commit history clean, we will try to squash the commits into a single commit for each merge onto the develop branch.

### Documentation

Currently, most of the developer documentation is available as READMEs in the code repositories. We describe the various API endpoints using the OpenAPI specification. The Rokwire Platform API documentation is available for your reference at https://api.rokwire.illinois.edu/docs/.
