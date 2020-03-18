# Contributing

[github-collab]: https://help.github.com/en/github/collaborating-with-issues-and-pull-requests

If you are new to GitHub, pull requests, or just curious to learn more about
the process, check out the [Collaboration][github-collab] chapter by GitHub.

## Opening a Pull Request

[fantom-fork]: https://github.com/fantom-lang/fantom/fork

1. [Fork][fantom-fork] the fantom repo and clone to your local system:
   ```
   git clone https://github.com/<YOUR_USERNAME>/fantom
   ```

2. Create a new branch for your patch:
   ```
   git checkout -b <YOUR_BRANCH_NAME> origin/master
   ```

3. Commit your changes:
   ```
   git add <filename>
   git commit -m "<message>"
   ```

4. Push branch to your forked repo:
   ```
   git push origin <YOUR_BRANCH_NAME>
   ```

5. Open a PR. Goto `https://github.com/<YOUR_USERNAME>/fantom` and find the
   green button to create a pull request.

6. Respond to feedback from maintainers, which may involve pushing additional
   commits to your PR branch.

7. After your PR has been accepted and merged, you can delete the branch:
   ```
   git branch -D <branch-name>       # delete local branch
   git push origin -d <branch-name>  # delete remote branch
   ```
