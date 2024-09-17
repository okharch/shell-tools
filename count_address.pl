#!/usr/bin/perl
use strict;
use warnings;

# Перевіряємо чи був переданий параметр URL
if (@ARGV != 1) {
    die "Використання: $0 <URL>\n";
}

# Отримуємо URL з аргументу командного рядка
my $url = $ARGV[0];

# Виконуємо curl для завантаження контенту, і iconv для перекодування з windows-1251 у utf-8
my $content = `curl -s $url | iconv -f windows-1251 -t utf-8`;

# Функція для підрахунку кількості будинків
sub count_addresses {
    my ($text) = @_;
    my $total = 0;

    # Пошук всіх "Буд." у тексті (в одному рядку)
    while ($text =~ /<div>Буд\.: ([^\n<>]+)/g) {
        my @building_list = split(/,\s*/, $1);
        $total += scalar @building_list;
    }

    return $total;
}

# Обчислюємо кількість адрес у тексті
my $total_addresses = count_addresses($content);

# Виводимо результат
print "Загальна кількість адрес: $total_addresses\n";

