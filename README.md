# haikubot

Quick-and-dirty script to generate YouTube playlists from the top posts on
[/r/youtubehaiku](https://reddit.com/r/youtubehaiku). Basically no polish past what I judge to be simple "enough."

### Usage

#### Setting up Ruby

Install [the latest version of Ruby](https://www.ruby-lang.org/en/downloads/). This should install RubyGems alongside
it, but if not, install this as well. Test the installation with `ruby --version`, then run the following command:

```
gem install google-api-client
```

#### Setting up Google authentication

Download `haikubot.rb` and place it in a directory. Then go to the
[Google API Developer Console](https://console.developers.google.com/) and create a new project called `haikubot`. Open
the project interface and click "Credentials" on the lefthand side, and create a new OAuth client ID. Give it an
arbitrary name and click "Create." Click the download icon on the new client ID and save the file as `secrets.json` in
the same directory as the script.

#### First run

Run the script from the command line as such:

```
ruby haikubot.rb
```

This will generate a URL and tell you to follow it. Upon following, it will take you to a URL on the `localhost` domain
(I can't figure out a better way to do this right now). There'll be a key in the URL; copy this back into the console
window and press ENTER. Congrats, you never have to do this again.

#### Subsequent runs

After the first-time authentication, the script can simply be run and completed with the above command.

### License

haikubot is made available under [the MIT license](https://opensource.org/licenses/MIT).
