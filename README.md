# Discourse doctor

In the spirit of `brew doctor` discourse-doctor is helping you troubleshoot your docker Discourse instance.

WARNING: it shouldn’t break anything in your instance, as it doesn’t have any destructive command, but please consider it
very alpha quality software.

## Usage

```
ssh -i YOUR_KEY root@MACHINE_IP
cd /var/discourse
./launcher enter app
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/jjaffeux/discourse-doctor/master/discourse-doctor.rb)"
```

## Contribute

Feel free to open a PR or come discuss it on https://meta.discourse.org/t/discourse-doctor/65169.

## How to hack on discourse-doctor

My workflow to dev this script is quite different from usual dev:

```
cd discourse-doctor
python -m SimpleHTTPServer 8000
# in another terminal window (see https://ngrok.com/ to get ngrok)
./ngrok http 8000
# and then use the ngrok url to call the script from my docker instance
ruby -e "$(curl -fsSL https://xxxx.ngrok.io/discourse-doctor.rb)"
```
