#!/usr/bin/env perl
use strict;
use warnings;

use Mojolicious::Lite;
use XML::FeedPP;
use URI;
use utf8;
use Encode;

get '/' => sub {
    # パラメータを取得
    my $self = shift;
    
    # 変数をセット
    my $title = 'Mojoliciousのテストサイト';
    my $description = 'm_shige1979がなんかいろいろやる目的のテストサイト'; 
    my $sub_title = '今回のやることはRSSを読み込んでリストを表示';   
 
    # 最初は配列をリファレンスで定義
    my $rss_list = [];
    
    # rssを取得
    my $rss_url = "http://b.hatena.ne.jp/entrylist/it?sort=hot&threshold=&mode=rss";    
    my $feed = XML::FeedPP->new($rss_url, utf8_flag => 1)
      or die XML::Feed->errstr;
    
    # リストに格納
    for my $entry($feed->get_item()){

        push @$rss_list, {
            title => ( $entry->title),
            url => $entry->link,
            count => $entry->get("hatena:bookmarkcount")
        }    
    }

    # テンプレート変数をセット
    $self->stash('title', $title);
    $self->stash('description', $description);
    $self->stash('subTitle', $sub_title);
    $self->stash('rssList', $rss_list);
    

    # indexを割り当て
    $self->render('index');
};

app->start;
__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html lang="ja">
    <head>
        <title><%= $title %></title>

        <link href="/css/bootstrap.min.css" rel="stylesheet">
        <link href="/css/bootstrap-theme.min.css" rel="stylesheet">
<!--        <link href="/css/docs.css" rel="stylesheet"> -->
<!--        <link href="/css/pygments-manni.css" rel="stylesheet"> -->
        <link href="/css/app.css" rel="stylesheet">

        <!--[if lt IE 9]>
        <script src="/js/html5shiv.js"></script>
        <script src="/js/respond.min.js"></script>
        <![endif]-->

    </head>
    <body data-twttr-rendered="true">

        <div class="navbar navbar-inverse bs-docs-nav">
            <div class="container">
                <a href="/" class="navbar-brand"><strong><%= $title %></strong></a>
            </div>
        </div>

        <div class="container-fluid">
            <div class="row-fluid">
                <div class="col-12">
                    <h2>
                        <%= $description %>
                    </h2>
                </div>
            </div>

            <div class="row-fluid">              
                <div class="col-12">
                    <div>
                        <h4><%= $subTitle %></h4>
                    </div>
                </div>
            </div>

            <div class="row-fluid">
                <div class="col-12">
                    <div class="list">
                        <div class="list_area">
                    % for my $item(@$rssList){
                        <a target="_blank" href="<%= $item->{url} %>">
                            <div class="bookmark_link">
                                <p>
                                    <%= $item->{title} %>
                                </p>
                                <em><%= $item->{count} %> users</em>
                            </div>
                        </a>
                    % }
                        </div>
                    </div>
                    <div style="clear: both;"></div>
                </div>
            </div>
             
        </div>

        <div class="footer">
		Created By <a target="_blank" href="https://twitter.com/m_shige1979">@m_shige1979</a>
	</div>
        
        <script type="text/javascript" src="/js/jquery.js"></script>
        <script type="text/javascript" src="/js/bootstrap.min.js"></script>
        <script type="text/javascript" src="/js/app.js"></script>
        
    </body>
</html>

