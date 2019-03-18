# Installation flow

- prepare
  - pack .git into `http/git.tar.gz`
  - create usable deployment script `http/deploy.sh`
- build
  - install vm
  - download `http/git.tar.gz` and extract into `/tmp/.git`
  - run deploy script
    - pull `/tmp/.git` into repo
    - run install script
      - run deploy script
        - setup modules, nodejs, etc
        - setup nginx
        - run update script
          - set motd
      - setup pw
      
