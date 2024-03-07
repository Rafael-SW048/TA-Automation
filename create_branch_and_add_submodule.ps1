# Navigate to the root of your repository
Set-Location -Path $original_path

# Create a new branch
$branch_name = Read-Host -Prompt "Enter your new branch name"
git checkout -b $branch_name

# Add the boilerplates submodule to the new branch
git submodule add -b boilerplates-ta https://github.com/Rafael-SW048/boilerplates.git

# Stage and commit the changes
git add .
git commit -m "Added boilerplates submodule"

# Navigate to the packer directory in the submodule
Set-Location -Path boilerplates

# Check if there are changes in the packer directory
git diff --quiet
if ($LASTEXITCODE -ne 0)
{
    # Prompt for the packer commit message
    $packer_commit_message = Read-Host -Prompt "Enter your packer commit message"

    # Stage, commit, and push changes in the packer directory
    git add .
    git commit -m $packer_commit_message
}

# Push the new branch to the remote repository
git push origin $branch_name

# Navigate back to the root of your repository
Set-Location -Path $original_path