# Discourse doctor

In the spirit of `brew doctor` discourse-doctor is helping you troubleshoot your docker Discourse instance.

WARNING: it shouldn’t break anything in your instance, as it doesn’t have any destructive command, but please consider it
very alpha quality software.

## Usage

```
ssh -i YOUR_KEY root@MACHINE_IP
cd /var/discourse
./launcher enter app
ruby -e "$(curl -fsSL https://gist.githubusercontent.com/jjaffeux/fe1387812fa6c015ebe5d59909b018bd/raw/discourse-doctor.rb)"
```


## Contribute

Feel free to open a PR or come discuss it on meta.discourse.org.
