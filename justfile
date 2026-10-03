set shell := ["bash", "-cu"]

clean:
    find infrastructure/ -type d -name '.terragrunt-cache' -prune -exec rm -rf -- {} +
    find infrastructure/ -type f -name '.terraform.lock.hcl' -prune -exec rm -rf -- {} +
