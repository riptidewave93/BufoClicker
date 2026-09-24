package Bufo::Browser::Templates;
use strict;
use warnings;
use Bufo::Browser::DOM;
my ( %actions, $counter );
sub esc    { return Bufo::Browser::DOM::escape( $_[0] ); }
sub idattr { return defined( $_[0] ) ? ' id="' . esc( $_[0] ) . '"' : ''; }

sub callback_attr {
    my ($cb) = @_;
    return ''                                      unless defined $cb;
    die 'Template callbacks must be Perl coderefs' unless ref($cb) eq 'CODE';
    my $id = 'template-' . ++$counter;
    $actions{$id} = $cb;
    return ' data-template-action="' . $id . '"';
}

sub activate {
    my ($event) = @_;
    my $el = $event->{target}->closest('[data-template-action]');
    return 0 unless defined $el;
    return 0 if $el->{disabled};
    my $id = $el->getAttribute('data-template-action');
    if ( $actions{$id} ) { $actions{$id}->(); return 1; }
    return 0;
}

sub release {
    my ($root) = @_;
    for my $el ( @{ Bufo::Browser::DOM::querySelectorAll( '[data-template-action]', $root ) } ) {
        delete $actions{ $el->getAttribute('data-template-action') };
    }
    return;
}

sub sectionHeader {
    my ( $title, $id ) = @_;
    return '<h2 class="section-header"' . idattr($id) . '>' . esc($title) . '</h2>';
}

sub panel {
    my ( $title, $content, $id, $class ) = @_;
    return
        '<div class="game-panel '
      . esc( $class || '' ) . '"'
      . idattr($id)
      . '><div class="panel-header">' . '<h2>'
      . esc($title) . '</h2>'
      . '</div><div class="panel-content">'
      . $content
      . '</div></div>';
}

sub button {
    my ( $text, $id, $cb, $class, $disabled ) = @_;
    return
        '<button class="game-button '
      . esc( $class || '' )
      . ( $disabled ? ' disabled' : '' ) . '"'
      . idattr($id)
      . callback_attr($cb)
      . ( $disabled ? ' disabled' : '' ) . '>'
      . esc($text)
      . '</button>';
}

sub iconButton {
    my ( $icon, $id, $tooltip, $cb, $class, $disabled ) = @_;
    return
        '<button class="icon-button '
      . esc( $class || '' )
      . ( $disabled ? ' disabled' : '' ) . '"'
      . idattr($id)
      . ( defined($tooltip) ? ' title="' . esc($tooltip) . '"' : '' )
      . callback_attr($cb)
      . ( $disabled ? ' disabled' : '' ) . '>'
      . $icon
      . '</button>';
}

sub progressBar {
    my ( $value, $max, $id, $label, $class ) = @_;
    $label = 1 unless defined $label;
    my $p = $max ? int( $value / $max * 100 ) : 0;
    return
        '<div class="progress-container '
      . esc( $class || '' ) . '"'
      . idattr($id)
      . '><div class="progress-bar" style="width:'
      . $p
      . '%"></div>'
      . ( $label ? '<span class="progress-label">' . $p . '%</span>' : '' )
      . '</div>';
}

sub resourceDisplay {
    my ( $amount, $name, $id, $show, $rate, $class ) = @_;
    return
        '<div class="resource-display '
      . esc( $class || '' ) . '"'
      . idattr($id)
      . '><div class="resource-count">'
      . esc($amount)
      . '</div>'
      . (
        $show && defined($rate)
        ? '<div class="production-rate">' . esc( $rate || 0 ) . '/sec</div>'
        : ''
      ) . '</div>';
}

sub tooltip {
    my ( $content, $title, $id, $class ) = @_;
    return
        '<div class="game-tooltip '
      . esc( $class || '' ) . '"'
      . idattr($id) . '>'
      . ( defined($title) ? '<div class="tooltip-header">' . esc($title) . '</div>' : '' )
      . '<div class="tooltip-content">'
      . $content
      . '</div></div>';
}

sub notification {
    my ( $message, $type, $id ) = @_;
    return
        '<div class="notification notification-'
      . esc( $type || 'info' ) . '"'
      . idattr($id)
      . '><div class="notification-content"><span class="notification-message">'
      . $message
      . '</span><button class="notification-close">&times;</button></div></div>';
}

sub modal {
    my ( $title, $content, $buttons, $id, $backdrop ) = @_;
    $backdrop = 1 unless defined $backdrop;
    return
        '<div class="modal"'
      . idattr($id)
      . ' data-close-on-backdrop="'
      . ( $backdrop ? 'true' : 'false' )
      . '"><div class="modal-content"><div class="modal-header"><h2>'
      . esc($title)
      . '</h2><button class="modal-close">&times;</button></div><div class="modal-body">'
      . $content
      . '</div>'
      . (
        $buttons && @$buttons ? '<div class="modal-footer">'
          . join( '',
            map { button( $_->{text}, undef, $_->{callback}, $_->{className} || 'modal-button' ) }
              @$buttons )
          . '</div>' : ''
      ) . '</div></div>';
}

sub tabContainer {
    my ( $tabs, $default, $id ) = @_;
    return '<div class="tab-container"' . idattr($id) . '><div class="tab-buttons">' . join(
        '',
        map {
                '<button class="tab-button'
              . ( $_->{id} eq $default ? ' active' : '' )
              . '" data-tab="'
              . esc( $_->{id} ) . '">'
              . ( $_->{icon} ? '<span class="tab-icon">' . $_->{icon} . '</span>' : '' )
              . '<span class="tab-label">'
              . esc( $_->{label} )
              . '</span>'
              . '</button>'
        } @$tabs
      )
      . '</div><div class="tab-contents">'
      . join(
        '',
        map {
                '<div id="tab-'
              . esc( $_->{id} )
              . '" class="tab-content" style="display:'
              . ( $_->{id} eq $default ? 'block' : 'none' ) . '">'
              . $_->{content}
              . '</div>'
        } @$tabs
      ) . '</div></div>';
}
1;
