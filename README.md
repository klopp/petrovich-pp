![Petrovich](https://raw.github.com/rocsci/petrovich/master/petrovich.png)

Склонение русских фамилий, имён и отчеств.

Порт [Ruby](https://github.com/petrovich/petrovich-ruby)-версии.

Лицензия MIT

##Использование

В библиотеку входит модуль ```Petrovich```

```perl
use lib 'path-to-module';
use PetrovichPP;

my $petrovich = new PetrovichPP(PetrovichPP::GENDER_MALE);
# пол можно менять и после вызова конструктора:
# $petrovich->setGenter(PetrovichPP::GENDER_FEMALE);

my $firstname = "Александр";
my $middlename = "Сергеевич";
my $lastname = "Пушкин";

print $petrovich->detectGender("Петровна");	# PetrovichPP::GENDER_FEMALE (см. пункт Пол)

print '<br /><strong>Родительный падеж:</strong><br />';
print $petrovich->firstName($firstname, PetrovichPP::CASE_GEN).'<br />'; # Александра
print $petrovich->middleName($middlename, PetrovichPP::CASE_GEN).'<br />'; # Сергеевича
print $petrovich->lastName($lastname, PetrovichPP::CASE_GEN).'<br />'; # Пушкина
my @fullName = $petrovich->fullName( $lastname, $firstname, $middlename, PetrovichPP::CASE_GEN );
print join( ', ', @fullname ); # Александра, Сергеевича, Пушкина
```

## Падежи
Названия суффиксов для методов образованы от английских названий соответствующих падежей. Полный список поддерживаемых падежей приведён в таблице:

| Суффикс метода | Падеж        | Характеризующий вопрос |
|----------------|--------------|------------------------|
| CASE_NOM | именительный | Кто? Что?            |
| CASE_GEN | родительный  | Кого? Чего?            |
| CASE_DAT | дательный    | Кому? Чему?            |
| CASE_ACC | винительный  | Кого? Что?             |
| CASE_INS | творительный | Кем? Чем?              |
| CASE_PREP | предложный   | О ком? О чём?          |

## Пол
Метод ```PetrovichPP::detectGender``` определяет пол по отчеству. Возвращаемое значение не зависит от пола, который выставлен в конструкторе или методе ```PetrovichPP::setGender()```.
Для полов определены следующие константы
* GENDER_ANDRO - пол не определен;
* GENDER_MALE - мужской пол;
* GENDER_FEMALE - женский пол.
