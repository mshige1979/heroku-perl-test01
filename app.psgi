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
    my $sub_title = 'テスト一覧';
    my $github = "https://github.com/mshige1979/heroku-perl-test01";

    # テンプレート変数をセット
    $self->stash('title', $title);
    $self->stash('description', $description);
    $self->stash('subTitle', $sub_title);
    $self->stash('github', $github);

    # indexを割り当て
    $self->render('index');

};

get '/rsslist' => sub {
    # パラメータを取得
    my $self = shift;
    
    # 変数をセット
    my $title = 'Mojoliciousのテストサイト';
    my $description = 'm_shige1979がなんかいろいろやる目的のテストサイト'; 
    my $sub_title = '今回のやることはRSSを読み込んでリストを表示';   
    my $github = "https://github.com/mshige1979/heroku-perl-test01";
 
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
    $self->stash('github', $github);
    $self->stash('rssList', $rss_list); 

    # indexを割り当て
    $self->render('rsslist');
};

app->start;

