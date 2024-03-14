
use v5.38;
use utf8;
use experimental qw[ class builtin try ];
use builtin      qw[ blessed refaddr true false ];
use open         qw[ :std :encoding(UTF-8) ];

use Data::Dumper;
use Time::HiRes   qw[ sleep ];

$|++;

use Coords;
use ANSI;
use Box;
use Card;

class DigitalDisplay {
    use ANSI;

    my $width  = 9;
    my $height = 9;

    my $on  = [ 0xFF, 0x00, 0x00 ];
    my $off = [ 0x33, 0x33, 0x33 ];
    my $nul = [ 0x22, 0x22, 0x22 ];

    my $top    = '  ▟███▙  ';
    my $bottom = '  ▜███▛  ';
    my $middle = '  ▟███▛  ';
    my @horz   = ('▟▙','██','▜▛');
    #my @spacer = map { join('', format_fg_color($nul), $_, format_reset()) }
    #             (' ▚ ▞ ',
    #              '  ▞  ',
    #              ' ▞ ▚ ');

    my @spacer = ('     ','     ','     ');

    my $line_break = format_line_break($width);

    method draw (@bits) {
        my (
            $_top,
            $_top_left, $_top_right,
            $_middle,
            $_bottom_left, $_bottom_right,
            $_bottom
        ) = @bits;
        return (
            join('',format_fg_color($_top          ? $on : $off ), $top    , format_reset()),

            join('',format_fg_color($_top_left     ? $on : $off ), $horz[0], format_reset(), $spacer[0],
                    format_fg_color($_top_right    ? $on : $off ), $horz[0], format_reset()),

            join('',format_fg_color($_top_left     ? $on : $off ), $horz[1], format_reset(), $spacer[1],
                    format_fg_color($_top_right    ? $on : $off ), $horz[1], format_reset()),

            join('',format_fg_color($_top_left     ? $on : $off ), $horz[2], format_reset(), $spacer[2],
                    format_fg_color($_top_right    ? $on : $off ), $horz[2], format_reset()),

            join('',format_fg_color($_middle       ? $on : $off ), $middle , format_reset()),

            join('',format_fg_color($_bottom_left  ? $on : $off ), $horz[0], format_reset(), $spacer[0],
                    format_fg_color($_bottom_right ? $on : $off ), $horz[0], format_reset()),

            join('',format_fg_color($_bottom_left  ? $on : $off ), $horz[1], format_reset(), $spacer[1],
                    format_fg_color($_bottom_right ? $on : $off ), $horz[1], format_reset()),

            join('',format_fg_color($_bottom_left  ? $on : $off ), $horz[2], format_reset(), $spacer[2],
                    format_fg_color($_bottom_right ? $on : $off ), $horz[2], format_reset()),

            join('',format_fg_color($_bottom       ? $on : $off ), $bottom , format_reset()),
        );
    }
}

sub zip ($b1, $b2, @rest) {
    my @out;
    foreach my $i (0 .. $#{$b1}) {
        push @out => $b1->[$i] . '  ' . ($b2->[$i] // '');
    }
    return \@out unless @rest;
    return zip(\@out, @rest);
}

my $dd = DigitalDisplay->new;

my %digits = (
    ' ' => [ $dd->draw(0,0,0,0,0,0,0) ],
    '0' => [ $dd->draw(1,1,1,0,1,1,1) ],
    '1' => [ $dd->draw(0,0,1,0,0,1,0) ],
    '2' => [ $dd->draw(1,0,1,1,1,0,1) ],
    '3' => [ $dd->draw(1,0,1,1,0,1,1) ],
    '4' => [ $dd->draw(0,1,1,1,0,1,0) ],
    '5' => [ $dd->draw(1,1,0,1,0,1,1) ],
    '6' => [ $dd->draw(1,1,0,1,1,1,1) ],
    '7' => [ $dd->draw(1,0,1,0,0,1,0) ],
    '8' => [ $dd->draw(1,1,1,1,1,1,1) ],
    '9' => [ $dd->draw(1,1,1,1,0,1,1) ],
);

my $x = 0;

print q[
╔═══╗ ╔═╗    ╔══╗  ═══╗ ╔      ╔══╗ ╔══╗  ════╦  ╔══╗ ╔═══╗ .
║   ║   ║       ║     ║ ║   ║  ║    ║        ╔╝  ║  ║ ║   ║ .
║   ║   ║   ╔═══╝   ══╣ ╚═══╣  ╚══╗ ╠═══╗  ═╦╩═ ╔╩══╣ ╚═══╣ .
║   ║   ║   ║         ║     ║     ║ ║   ║  ╔╝   ║   ║     ║ .
╚═══╝ ══╩══ ╚═══╝ ╚═══╝     ║ ╚═══╝ ╚═══╝  ║    ╚═══╝  ╚══╝ .

╔═══╗ ╔═╗      ╔══╗  ═══╗   ╔      ╔══╗ .
║   ║   ║   ▪     ║     ║ ▪ ║   ║  ║    .
║   ║   ║     ╔═══╝   ══╣   ╚═══╣  ╚══╗ .
║   ║   ║   ▪ ║         ║ ▪     ║     ║ .
╚═══╝ ══╩══   ╚═══╝ ╚═══╝       ║ ╚═══╝ .

╔═══╗ ╔═╗        ╔══╗  ═══╗     ╔      ╔══╗ .
║   ║   ║     ╱     ║     ║   ╱ ║   ║  ║    .
║   ║   ║    ╱  ╔═══╝   ══╣  ╱  ╚═══╣  ╚══╗ .
║   ║   ║   ╱   ║         ║ ╱       ║     ║ .
╚═══╝ ══╩══     ╚═══╝ ╚═══╝         ║ ╚═══╝ .


  ▟███▙      ▟███▙          ▟███▙      ▟███▙          ▟███▙      ▟███▙    .
▟▙     ▟▙  ▟▙     ▟▙      ▟▙     ▟▙  ▟▙     ▟▙      ▟▙     ▟▙  ▟▙     ▟▙  .
██     ██  ██     ██  ▟▙  ██     ██  ██     ██  ▟▙  ██     ██  ██     ██  .
▜▛     ▜▛  ▜▛     ▜▛  ▜▛  ▜▛     ▜▛  ▜▛     ▜▛  ▜▛  ▜▛     ▜▛  ▜▛     ▜▛  .
  ▟███▛      ▟███▛          ▟███▛      ▟███▛          ▟███▛      ▟███▛    .
▟▙     ▟▙  ▟▙     ▟▙  ▟▙  ▟▙     ▟▙  ▟▙     ▟▙  ▟▙  ▟▙     ▟▙  ▟▙     ▟▙  .
██     ██  ██     ██  ▜▛  ██     ██  ██     ██  ▜▛  ██     ██  ██     ██  .
▜▛     ▜▛  ▜▛     ▜▛      ▜▛     ▜▛  ▜▛     ▜▛      ▜▛     ▜▛  ▜▛     ▜▛  .
  ▜███▛      ▜███▛          ▜███▛      ▜███▛          ▜███▛      ▜███▛    .


  ▟███▙      ▟███▙              ▟███▙      ▟███▙              ▟███▙      ▟███▙      .
▟▙     ▟▙  ▟▙     ▟▙       ▟▛ ▟▙     ▟▙  ▟▙     ▟▙       ▟▛ ▟▙     ▟▙  ▟▙     ▟▙    .
██     ██  ██     ██      ▟▛  ██     ██  ██     ██      ▟▛  ██     ██  ██     ██    .
▜▛     ▜▛  ▜▛     ▜▛     ▟▛   ▜▛     ▜▛  ▜▛     ▜▛     ▟▛   ▜▛     ▜▛  ▜▛     ▜▛    .
  ▟███▛      ▟███▛      ▟▛      ▟███▛      ▟███▛      ▟▛      ▟███▛      ▟███▛      .
▟▙     ▟▙  ▟▙     ▟▙   ▟▛     ▟▙     ▟▙  ▟▙     ▟▙   ▟▛     ▟▙     ▟▙  ▟▙     ▟▙    .
██     ██  ██     ██  ▟▛      ██     ██  ██     ██  ▟▛      ██     ██  ██     ██    .
▜▛     ▜▛  ▜▛     ▜▛ ▟▛       ▜▛     ▜▛  ▜▛     ▜▛ ▟▛       ▜▛     ▜▛  ▜▛     ▜▛    .
  ▜███▛      ▜███▛              ▜███▛      ▜███▛              ▜███▛      ▜███▛      .

];

exit;

while (1) {
    say format_move_cursor(1, 1),
        join "\n" => @{
            zip( map $digits{$_}, split '' => sprintf '%-6d' => $x++ )
        };
    sleep 0.03;
}

__END__


╔═══╗ ╔═╗    ╔══╗  ═══╗ ╔      ╔══╗ ╔══╗  ════╦  ╔══╗ ╔═══╗ .
║   ║   ║       ║     ║ ║   ║  ║    ║        ╔╝  ║  ║ ║   ║ .
║   ║   ║   ╔═══╝   ══╣ ╚═══╣  ╚══╗ ╠═══╗  ═╦╩═ ╔╩══╣ ╚═══╣ .
║   ║   ║   ║         ║     ║     ║ ║   ║  ╔╝   ║   ║     ║ .
╚═══╝ ══╩══ ╚═══╝ ╚═══╝     ║ ╚═══╝ ╚═══╝  ║    ╚═══╝  ╚══╝ .

╔═══╗ ╔═╗      ╔══╗  ═══╗   ╔      ╔══╗ .
║   ║   ║   ▪     ║     ║ ▪ ║   ║  ║    .
║   ║   ║     ╔═══╝   ══╣   ╚═══╣  ╚══╗ .
║   ║   ║   ▪ ║         ║ ▪     ║     ║ .
╚═══╝ ══╩══   ╚═══╝ ╚═══╝       ║ ╚═══╝ .

╔═══╗ ╔═╗        ╔══╗  ═══╗     ╔      ╔══╗ .
║   ║   ║     ╱     ║     ║   ╱ ║   ║  ║    .
║   ║   ║    ╱  ╔═══╝   ══╣  ╱  ╚═══╣  ╚══╗ .
║   ║   ║   ╱   ║         ║ ╱       ║     ║ .
╚═══╝ ══╩══     ╚═══╝ ╚═══╝         ║ ╚═══╝ .



  ▟███▙    .
▟▙ ▚ ▞ ▟▙  .
██  ▞  ██  .
▜▛ ▞ ▚ ▜▛  .
  ▟███▛    .
▟▙ ▚ ▞ ▟▙  .
██  ▞  ██  .
▜▛ ▞ ▚ ▜▛  .
  ▜███▛    .


      ▟▛ .
     ▟▛  .
    ▟▛   .
   ▟▛    .
  ▟▛     .
 ▟▛      .
▟▛       .

   .
   .
▟▙ .
▜▛ .
   .
▟▙ .
▜▛ .
   .
   .

  ▟███▙      ▟███▙          ▟███▙      ▟███▙          ▟███▙      ▟███▙    .
▟▙     ▟▙  ▟▙     ▟▙      ▟▙     ▟▙  ▟▙     ▟▙      ▟▙     ▟▙  ▟▙     ▟▙  .
██     ██  ██     ██  ▟▙  ██     ██  ██     ██  ▟▙  ██     ██  ██     ██  .
▜▛     ▜▛  ▜▛     ▜▛  ▜▛  ▜▛     ▜▛  ▜▛     ▜▛  ▜▛  ▜▛     ▜▛  ▜▛     ▜▛  .
  ▟███▛      ▟███▛          ▟███▛      ▟███▛          ▟███▛      ▟███▛    .
▟▙     ▟▙  ▟▙     ▟▙  ▟▙  ▟▙     ▟▙  ▟▙     ▟▙  ▟▙  ▟▙     ▟▙  ▟▙     ▟▙  .
██     ██  ██     ██  ▜▛  ██     ██  ██     ██  ▜▛  ██     ██  ██     ██  .
▜▛     ▜▛  ▜▛     ▜▛      ▜▛     ▜▛  ▜▛     ▜▛      ▜▛     ▜▛  ▜▛     ▜▛  .
  ▜███▛      ▜███▛          ▜███▛      ▜███▛          ▜███▛      ▜███▛    .


  ▟███▙      ▟███▙              ▟███▙      ▟███▙              ▟███▙      ▟███▙      .
▟▙     ▟▙  ▟▙     ▟▙       ▟▛ ▟▙     ▟▙  ▟▙     ▟▙       ▟▛ ▟▙     ▟▙  ▟▙     ▟▙    .
██     ██  ██     ██      ▟▛  ██     ██  ██     ██      ▟▛  ██     ██  ██     ██    .
▜▛     ▜▛  ▜▛     ▜▛     ▟▛   ▜▛     ▜▛  ▜▛     ▜▛     ▟▛   ▜▛     ▜▛  ▜▛     ▜▛    .
  ▟███▛      ▟███▛      ▟▛      ▟███▛      ▟███▛      ▟▛      ▟███▛      ▟███▛      .
▟▙     ▟▙  ▟▙     ▟▙   ▟▛     ▟▙     ▟▙  ▟▙     ▟▙   ▟▛     ▟▙     ▟▙  ▟▙     ▟▙    .
██     ██  ██     ██  ▟▛      ██     ██  ██     ██  ▟▛      ██     ██  ██     ██    .
▜▛     ▜▛  ▜▛     ▜▛ ▟▛       ▜▛     ▜▛  ▜▛     ▜▛ ▟▛       ▜▛     ▜▛  ▜▛     ▜▛    .
  ▜███▛      ▜███▛              ▜███▛      ▜███▛              ▜███▛      ▜███▛      .





