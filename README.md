This is a simple bash script for offline reading of Hacker News
(news.ycombinator.com). By default it downloads the current
front page (the top 30 items) along with their comment threads
for offline reading.

```
bash hn_offline.sh
```

You can also download the frontpage from a past day:

```
bash hn_offline.sh --date 2021-12-11
```

External links are not archived; these are still offline links.

It does not archive other features of the website, like:
* User pages
* The 'from' pages to discover other articles from a certain source
* Anything after page 1

It also doesn't download any non-HTML assets like CSS or Javascript. This
means some functions on the website don't work; for example, you can't
collapse threads or hide individual posts.

# What's the purpose of this?

I use it to use Hacker News like a "newspaper" instead of a constantly
changing page that I try to check every day or even multiple times a day to
see if there's something new.

I run a weekly cronjob that refreshes an offline copy from earlier in the week
on a local web server. Then, I can point my browser at that local copy
instead of at news.ycombinator.com.

# Is this allowed?

Before using any crawling tool you should consult the website's robots.txt.

HN's [robots.txt](https://news.ycombinator.com/robots.txt), as of
2023-01-21, does not forbid crawling the main page or `/item?` paths. We
use a default sleep of 31 seconds between downloads to comply with the
`Crawl-delay` of 30 seconds.
