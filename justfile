set shell := ["bash", "-cu"]

clean:
    find infrastructure/ -type d -name '.terragrunt-cache' -prune -exec rm -rf -- {} +
    find infrastructure/ -type f -name '.terraform.lock.hcl' -prune -exec rm -rf -- {} +

global-clean: clean
    rm -rf -- "${XDG_CACHE_HOME:-$HOME/.cache}/terragrunt/cas"
