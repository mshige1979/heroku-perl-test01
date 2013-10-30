#!/usr/bin/env perl
use strict;
use warnings;

use Mojolicious::Lite;
use XML::FeedPP;
use URI;
use utf8;
use Encode;
use Net::Twitter;
use DateTime;
use Mojo::JSON;

# デバッグ用
use Data::Dumper::AutoEncode;

# 設定ファイルを読み込み
my $config = plugin('Config', {file => 'app.conf'});

## Twitterのモジュール設定
my $nt = Net::Twitter->new(
    traits => [qw/API::RESTv1_1/],
    consumer_key => $ENV{'TW_CONSUMER_KEY'},
    consumer_secret => $ENV{'TW_CONSUMER_SECRET'},
);

my $jsList = [];

# なんかよくわからんけどクッキーのセキュアにするとかなんとか
app->secret($ENV{'MOJO_COOKIE_SECRET'});

# TOPページ
get '/' => sub {
    
    # パラメータを取得
    my $self = shift;

    # 変数をセット
    my $sub_title = 'テスト一覧';

    # テンプレート変数をセット
    $self->stash('title', $config->{title});
    $self->stash('description', $config->{description});
    $self->stash('github', $config->{github});
    $self->stash('subTitle', $sub_title);
    $self->stash('jsList', $jsList);

    # indexを割り当て
    $self->render('index');

};

# RSS一覧
get '/rsslist' => sub {
    # パラメータを取得
    my $self = shift;
    
    # 変数をセット
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
    $self->stash('title', $config->{title});
    $self->stash('description', $config->{description});
    $self->stash('github', $config->{github});
    $self->stash('subTitle', $sub_title);
    $self->stash('rssList', $rss_list); 
    $self->stash('jsList', $jsList);

    # indexを割り当て
    $self->render('rsslist');
};

# twitter画面
get '/twitter/' => sub {
    
    # パラメータを取得
    my $self = shift;

    # tweet用
    my $screen_name;
    my $tweets;

    # アクセストークンチェック
    if($self->session('access_token')){
        # セッション用アクセストークンを取得
        my $access_token = $self->session('access_token');
        my $access_token_secret = $self->session('access_token_secret');
        
        # 取得したアクセストークンを設定
        $nt->access_token($access_token);
        $nt->access_token_secret($access_token_secret);
        
        my %arg;
        $arg{'count'} = 200;

        # ホームタイムラインを取得して配列に格納
        my $list = [];
        for my $tweet (@{$nt->home_timeline({%arg})}){
            my $tweetData = {};
            
            # パラメータ設定
            $tweetData->{id} =  $tweet->{id};
            $tweetData->{text} =  $tweet->{text};
            $tweetData->{created_at} =  $tweet->{created_at};
            $tweetData->{profile_image_url} = $tweet->{user}->{profile_image_url};
            $tweetData->{screen_name} = $tweet->{user}->{screen_name};
            $tweetData->{in_reply_to_status_id} = $tweet->{in_reply_to_status_id};
            $tweetData->{source} = $tweet->{source};
            $tweetData->{name} = $tweet->{user}->{name};            

            if($tweet->{retweeted_status}){
                
                my $retweeted = $tweet->{retweeted_status};

                $tweetData->{retweete} = {};
                $tweetData->{retweete}->{status} = "1";
                $tweetData->{retweete}->{profile_image_url} = $retweeted->{user}->{profile_image_url};
                $tweetData->{retweete}->{name} = $retweeted->{user}->{name};
                $tweetData->{retweete}->{screen_name} = $retweeted->{user}->{screen_name};
                $tweetData->{retweete}->{text} = $retweeted->{text};

            }

            # 配列に設定
            push @$list, $tweetData;
        }

        # 認証情報がある場合に表示
        $screen_name = $self->session('screen_name');
        $tweets = $list;

    }

    # 変数をセット
    my $sub_title = 'Twitterテストページ';

    # テンプレート変数をセット
    $self->stash('title', $config->{title});
    $self->stash('description', $config->{description});
    $self->stash('github', $config->{github});
    $self->stash('subTitle', $sub_title);
    $self->stash('jsList', $jsList);

    $self->stash('screen_name', $screen_name);
    $self->stash('tweets', $tweets);

    # twitterを割り当て
    $self->render('twitter');
};

# Twitterでログイン
get '/twitter/login' => sub {

    # パラメータを取得
    my $self = shift;
    
    # リクエスト取得
    my $url = $nt->get_authorization_url(
        callback => $self->req->url->base . '/twitter/callback'
    );

    # セッションデータへ保存
    $self->session(token => $nt->request_token);
    $self->session(token_secret => $nt->request_token_secret);
 
    # リダイレクト
    $self->redirect_to($url);

};

# Twitterでログアウト
get '/twitter/logout' => sub {
    # パラメータを取得
    my $self    = shift;
    
    # セッションを開放
    $self->session(expires => 1);
    
    # リダイレクト
    $self->redirect_to('/twitter/');

};

# Twitterでログイン
get '/twitter/callback' => sub {

    # パラメータを取得
    my $self = shift;
    
    # deniedがない場合に処理を実施
    unless ( $self->req->param('denied') ) {
         
        my $token = $self->session('token');        
        my $token_secret = $self->session('token_secret');

        # セッションよりトークンを取得して設定
        $nt->request_token($token);
        $nt->request_token_secret($token_secret);
 
        my $verifier = $self->req->param('oauth_verifier');
        my ($access_token, $access_token_secret, $user_id, $screen_name) = $nt->request_access_token(verifier => $verifier);

        # アクセストークンをセッションへ保存
        $self->session(access_token => $access_token);
        $self->session(access_token_secret => $access_token_secret);
        $self->session(screen_name => $screen_name);

    }

    # Twitterのページへリダイレクト
    $self->redirect_to('/twitter/');

};

# chatの画面
get '/chat' => sub {
    
     # パラメータを取得
    my $self = shift;

    my $jslist = ['chat.js'];

    # URL
    my $url_base = $self->req->url->base;
    $url_base =~ s/http/ws/g;
    $self->stash('url_base', $url_base);

    # 変数をセット
    my $sub_title = 'WebScoketでチャットのテスト';

    # テンプレート変数をセット
    $self->stash('title', $config->{title});
    $self->stash('description', $config->{description});
    $self->stash('github', $config->{github});
    $self->stash('subTitle', $sub_title);

    $self->stash('jsList', $jslist);

    # chatページを割り当て
    $self->render('chat');
};

my $clients = {};

# WebSocketの処理
websocket '/echo' => sub {
    my $self = shift;

    my $id = sprintf "%s", $self->tx;
    $clients->{$id} = $self->tx;

#    $self->receive_message(  # もう使えない
    $self->on(message => 
        sub {
            my ($self, $msg) = @_;

            my $json = Mojo::JSON->new;
            my $dt   = DateTime->now( time_zone => 'Asia/Tokyo');

            for (keys %$clients) {
#                $clients->{$_}->send_message( # これも？
                $clients->{$_}->send(
                    $json->encode({
                        hms  => $dt->hms,
                        text => $msg,
                    })
                );
            }
        }
    );

#    $self->finished( # 別名
    $self->on(finish => 
        sub {
            delete $clients->{$id};
        }
    );
};


# start
app->start;

