# Save the current directory
$original_path = Get-Location

# Check if there are changes in the main project
git diff --quiet
$unstaged_changes = $LASTEXITCODE -ne 0
git diff --cached --quiet
$staged_changes = $LASTEXITCODE -ne 0

if ($unstaged_changes -or $staged_changes)
{
    # Prompt for the main project commit message
    $main_commit_message = Read-Host -Prompt "Enter your main project commit message"

    # Stage, commit, and push changes in the main project
    git add .
    git commit -m $main_commit_message
    git push origin main
}

# Navigate to the submodule directory
Set-Location -Path boilerplates

# Check if there are changes in the submodule
git diff --quiet
$unstaged_changes = $LASTEXITCODE -ne 0
git diff --cached --quiet
$staged_changes = $LASTEXITCODE -ne 0

# Check for untracked files
$untracked_files = git ls-files --others --exclude-standard
$has_untracked_files = -not [string]::IsNullOrEmpty($untracked_files)

# Always stage all changes and untracked files
git add .

if ($unstaged_changes -or $staged_changes -or $has_untracked_files)
{
    # Prompt for the submodule commit message
    $submodule_commit_message = Read-Host -Prompt "Enter your submodule commit message"

    # Commit and push changes in the submodule
    git commit -m $submodule_commit_message
    git push origin boilerplates-ta
}

# Navigate back to the main project directory
Set-Location -Path $original_path

# Always stage the updated submodule and any untracked files
git add .

# Prompt for the main project commit message
$main_commit_message = Read-Host -Prompt "Enter your main project commit message for updating the submodule"

# Commit and push the main project with the updated submodule
git commit -m $main_commit_message
git push origin main