This is a simple wget wrapper for offline reading of Hacker News
(news.ycombinator.com). By default it downloads the current
front page (the top 30 items) along with the comment threads
for offline reading.

```
bash hn_offline.sh
```

You can also download the frontpage from a past day:

```
bash hn_offline.sh --date 2021-12-11
```

External links are not archived; these are still online links.

It does not archive other parts of the website, like:
* User pages
* The 'from' pages to discover other articles from a certain source
* Anything after page 1

# What's the purpose of this?

I use it to use Hacker News like a "newspaper" instead of a constantly
changing page that I try to check every day or even multiple times a day to
see if there's something new.

I run a daily cronjob at the end of the day that downloads the front
page to a local web server:

```
pushd $HOME/utils/hn_offline
bash hn_offline.sh --date "$(date +"%Y-%m-%d")"
rsync --verbose --times --stats --recursive \
  "./out/news.ycombinator.com/" \
  "/var/www/html/hackernews"
popd
```

Then, I can point my browser at that local server
instead of at news.ycombinator.com.

# Is this allowed?

Before using any crawling tool you should consult the website's robots.txt.

HN's [robots.txt](https://news.ycombinator.com/robots.txt), as of
2023-01-21, does not forbid crawling the main page or `/item?` paths,
and specifies a Crawl-delay of 30 seconds.

wget, in recursive mode, respects robots.txt by default. Additionally,
the script specifies a 60 second (+- 50%) wait between downloads.
