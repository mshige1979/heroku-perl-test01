#!/usr/bin/env perl
use strict;
use warnings;

use Mojolicious::Lite;

get '/' => sub {
    # パラメータを取得
    my $self = shift;
    
    # テンプレート変数をセット
    $self->stash('title', 'test site');
    $self->stash('name', 'm_shige1979');

    # indexを割り当て
    $self->render('index');
};

app->start;
__DATA__

@@ index.html.ep
<!DOCTYPE html>
<html>
    <head>
        <title><%= $title %></title>
    </head>
    <body>
        こんにちは <%= $name %> さん
    </body>
</html>

