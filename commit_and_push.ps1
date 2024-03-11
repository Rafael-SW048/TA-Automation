# Save the current directory
$original_path = Get-Location

# Check if there are changes in the main project
git diff --quiet
if ($LASTEXITCODE -ne 0)
{
    # Prompt for the main project commit message
    $main_commit_message = Read-Host -Prompt "Enter your main project commit message"

    # Stage, commit, and push changes in the main project
    git add .
    git commit -m $main_commit_message
    git push origin main
}
else
{
    git diff --cached --quiet
    if ($LASTEXITCODE -ne 0)
    {
        # Prompt for the main project commit message
        $main_commit_message = Read-Host -Prompt "Enter your main project commit message"

        # Stage, commit, and push changes in the main project
        git add .
        git commit -m $main_commit_message
        git push origin main
    }
}

# Navigate to the submodule directory
Set-Location -Path boilerplates

# Check if there are changes in the submodule
git diff --quiet
if ($LASTEXITCODE -ne 0)
{
    # Prompt for the submodule commit message
    $submodule_commit_message = Read-Host -Prompt "Enter your submodule commit message"

    # Stage, commit, and push changes in the submodule
    git add .
    git commit -m $submodule_commit_message
    git push origin boilerplates-ta
}
else
{
    git diff --cached --quiet
    if ($LASTEXITCODE -ne 0)
    {
        # Prompt for the submodule commit message
        $submodule_commit_message = Read-Host -Prompt "Enter your submodule commit message"

        # Stage, commit, and push changes in the submodule
        git add .
        git commit -m $submodule_commit_message
        git push origin boilerplates-ta
    }
}

# Return to the original directory
Set-Location -Path $original_path