#!/usr/bin/perl -w


use strict;
use warnings;

use Data::Dumper;

use XML::LibXML::Reader;
use lib './bin';
use XMLlists;


my @enums;
my %enumValues;

my @enumsToSkip =
(
	"AnimationOperatorTypes",
	"FunctionTypes",
	"DiplomacyPowerTypes",
	"AutomateTypes",
	"DirectionTypes",
	"InterfaceVisibility",
	"ArtStyleTypes",
	"ContactTypes",
	"CitySizeTypes",
	"FootstepAudioTypes",
);

my @enumsToNotUseEnumCounter =
(
	"AnimationOperatorTypes",
	"ArtStyleTypes",
	"AutomateTypes",
	"FootstepAudioTypes",
);


my $FILE         = getAutoDir() . "/AutoGlobalDefineEnum.h";
my $FILE_CPP     = getAutoDir() . "/AutoGlobalDefineEnumCpp.h";

my $output         = "";

$output .= "#ifndef AUTO_XML_ENUM_GLOBAL\n";
$output .= "#define AUTO_XML_ENUM_GLOBAL\n";
$output .= "\n";
$output .= "// Autogenerated file. Do not edit!!!\n";
$output .= "\n";



getTypesInFile("GlobalTypes.xml");



foreach my $enum (@enums)
{
	next if shouldSkipEnum($enum);
	
	$output .= "enum " . $enum . "\n{\n";
	$output .= "\tNO_" . getEnumUpperCase($enum) . " = -1,\n";
	
	foreach my $value (@{$enumValues{$enum}})
	{
		$output .= "\t";
		$output .= $value;
		$output .= ",\n";
	}
	my $upperName = getEnumUpperCase($enum);
	
	$output .= "\n\t" . getMaxName($upperName) . ",\n";
	$output .= "\t" . getFirstName($upperName) . " = 0,\n";
	$output .= "};\n\n";
}

foreach my $enum (@enums)
{
	next if shouldSkipEnum($enum);
	my $upperName = getEnumUpperCase($enum);
	
	handleOperators($enum);
	
	$output .= "template <> struct VARINFO<" . $enum . ">\n{\n";
	$output .= "\tstatic const char* getName() { return \"" . $enum . "\";}\n";
	$output .= "\tstatic $enum start() { return " . getFirstName($upperName) . ";}\n";
	$output .= "\tstatic $enum end() { return " . getMaxName($upperName) . ";}\n";
	$output .= "};\n";
}

$output .= "#endif\n";

writeFile($FILE        , \$output        );

$output = "\n// autogeneted file!\n// do not edit\n\n";
$output .= "#include \"../CvEnumsFunctions.h\"\n\n";

foreach my $enum (@enums)
{
	$output .= "\ntemplate<>\n";
	$output .= "const char* getTypeStr(" . $enum . " eIndex)\n{\n";
	$output .= "\tswitch(eIndex)\n\t{\n";
	
	my $i = 0;
	foreach my $value (@{$enumValues{$enum}})
	{
		$output .= "\t\tcase ";
		if (useEnumNamesAsCounter($enum))
		{
			$output .= $value;
		}
		else
		{
			$output .= $i;
			$i = $i + 1;
		}
		$output .= ": return \"" . $value . "\";\n";
	}
	$output .= "\t}\n";
	$output .= "\treturn \"\";\n";
	$output .= "}\n";

}

writeFile($FILE_CPP     , \$output        );


exit();



sub getTypesInFile
{
	my $filename = shift;
	
	my $fileWithPath = getFileWithPath($filename);
	
	if ($fileWithPath)
	{
		my $reader = XML::LibXML::Reader->new(location => $fileWithPath)
			or die "cannot read file '$fileWithPath': $!\n";
		
		my $enumSet = 0;
		my $enum = "";
		
		
		while($reader->read)
		{
			if ($reader->nodeType == 1 and $reader->depth == 1)
			{
				$enumSet = 0;
				$enum = getEnumName($reader->name);
			}
			elsif ($reader->nodeType == 3 and $reader->depth == 3)
			{
				if ($enumSet == 0)
				{
					$enumSet = 1;
					push(@enums, $enum);
					$enumValues{$enum} = ();
					
				}
				push(@{$enumValues{$enum}}, $reader->value);
			}
		}
	}
}

sub getEnumName
{
	my $enum = shift;
	return "InterfaceVisibility" if $enum eq "InterfaceVisibilityTypes";
	return $enum;
}

sub getMaxName
{
	my $name = shift;
	
	return "MAX_NUM_SYMBOLS" if $name eq "FONT_SYMBOLS";
	
	return "NUM_" . $name . "_TYPES";
}

sub getFirstName
{
	my $name = shift;
	
	return "FIRST_FONTSYMBOL" if $name eq "FONT_SYMBOLS";
	
	return "FIRST_" . $name;
}

sub shouldSkipEnum
{
	my $enum = shift;
	
	foreach my $loop_enum (@enumsToSkip)
	{
		return 1 if $enum eq $loop_enum;
	}
	return 0;
}

sub useEnumNamesAsCounter
{
	my $enum = shift;
	
	foreach my $loop_enum (@enumsToNotUseEnumCounter)
	{
		return 0 if $enum eq $loop_enum;
	}
	return 1;
}

sub getChild
{
	my $parent = shift;
	my $name = shift;
	
	my $element = $parent->firstChild;
	
	while (1)
	{
		return if (ref($element) eq "");
		if (ref($element) eq "XML::LibXML::Element")
		{
			return $element if $name eq "" or $element->nodeName eq $name;
		}
		$element = $element->nextSibling;
	}
}

sub nextSibling
{
	my $element = shift;
	
	$element = $element->nextSibling;
	while (ref($element) ne "XML::LibXML::Element" and ref($element) ne "")
	{
		$element = $element->nextSibling;
	}
	return $element;
}

sub getEnumUpperCase
{
	my $original = shift;
	my $result = substr($original, 0, 1);
	
	$original = substr($original, 1);
	
	if (substr($original, -5) eq "Types")
	{
		$original = substr($original, 0, -5);
	}
	
	foreach my $char (split //, $original)
	{
		my $newChar = uc($char);
		$result .= "_" if $char eq $newChar;
		$result .= $newChar;
	}
	
	return $result;
}

sub handleOperators
{
	my $type = shift;
	
	operatorAdd($type, "+");
	operatorAdd($type, "-");
	
	operator($type, "++", 0);
	operator($type, "++", 1);
	operator($type, "--", 0);
	operator($type, "--", 1);
}

sub operator
{
	my $type = shift;
	my $operator = shift;
	my $postfix = shift;
	
	$output .= "static inline $type";
	$output .= "&" unless $postfix;
	$output .= " operator" . $operator . "($type& c";
	$output .= ", int" if $postfix;
	$output .= ")\n";
	$output .= "{\n";
	$output .= "\t" . $type . " cache = c;\n" if $postfix;
	$output .= "\tc = static_cast<$type>(c " . substr($operator, 0, 1) . " 1);\n";
	$output .= "\treturn ";
	$output .=  "c" unless $postfix;
	$output .=  "cache" if $postfix;
	$output .= ";\n";
	$output .= "};\n";
}

sub operatorAdd
{
	my $type = shift;
	my $operator = shift;
	
	$output .= "static inline $type operator" . $operator . "(const $type& A, const $type& B)\n";
	$output .= "{\n";
	$output .= "\treturn static_cast<$type>((int)A $operator (int)B);\n";
	$output .= "};\n";
}
