using Test
using LazyJSON

@testset "SplicedString" begin

sv = LazyJSON.SplicedStrings.splice_vector
SS = LazyJSON.SplicedStrings.SplicedString

@test SS("Foo").v == ["Foo"]
@test SS(SubString("Food", 1, 3)).v == ["Foo"]
@test SS(SubString(SS("Food"), 1, 3)).v == ["Foo"]
@test SS(SubString(SS("Food"), 1, 3)).v[1] isa SubString{String}
@test SS("Foo", "Bar").v == ["Foo", "Bar"]
@test SS(SS("Foo", "Bar")).v == ["Foo", "Bar"]

@test sv(         "Foo"                              ) == ["Foo"]
@test sv(   [     "Foo",       "Bar"                ]) == ["Foo", "Bar"]
@test sv(   (     "Foo",       "Bar"                )) == ["Foo", "Bar"]
@test sv(     SS(["Foo",       "Bar"])               ) == ["Foo", "Bar"]
@test sv(   [ SS(["Foo"]), SS(["Bar"])              ]) == ["Foo", "Bar"]
@test sv(   [ SS( "Foo",       "Bar" ), SS( "Boo" ) ]) == ["Foo", "Bar", "Boo"]
@test sv(   [ SS(["Foo",       "Bar"]), SS( "Boo" ) ]) == ["Foo", "Bar", "Boo"]
@test sv(   [ SS(["Foo",       "Bar"]), SS(["Boo"]) ]) == ["Foo", "Bar", "Boo"]
@test sv(   [ SS(["Foo",       "Bar"]),     "Boo"   ]) == ["Foo", "Bar", "Boo"]
@test sv(   [     "Foo",   SS(["Bar",       "Boo"]) ]) == ["Foo", "Bar", "Boo"]

@test SS(         "Foo"                              ) == "Foo"
@test SS(   [     "Foo"                             ]) == "Foo"
@test SS(         "Foo",       "Bar"                 ) == "FooBar"
@test SS(   [     "Foo",       "Bar"                ]) == "FooBar"
@test SS(     SS(["Foo",       "Bar"])               ) == "FooBar"
@test SS(   [ SS(["Foo",       "Bar"])              ]) == "FooBar"
@test SS(     SS(["Foo"]), SS(["Bar"])               ) == "FooBar"
@test SS(   [ SS(["Foo"]), SS(["Bar"])              ]) == "FooBar"
@test SS(     SS(["Foo",       "Bar"]), SS(["Boo"])  ) == "FooBarBoo"
@test SS(         "Foo",       "Bar",       "Boo"    ) == "FooBarBoo"
@test SS(     SS(["Foo",       "Bar"]),     "Boo"    ) == "FooBarBoo"
@test SS(   [ SS(["Foo",       "Bar"]),     "Boo"   ]) == "FooBarBoo"
@test SS(         "Foo",   SS(["Bar",       "Boo"])  ) == "FooBarBoo"
@test SS(   [     "Foo",   SS(["Bar",       "Boo"]) ]) == "FooBarBoo"
@test SS(   [     "Foo",   SS(["Bar",       "Boo"]) ]) == "FooBarBoo"


# Simple insert
ss = SS("Foo", "Bar")
splice!(ss, 1 << 40 | 1, 1 << 40 | 0, "d")
@test ss == "FoodBar"
@test ss.v == ["Foo", "d", "Bar"]

# Replace fragment prefix
ss = SS("Foo", "Bar")
splice!(ss, 1 << 40 | 1, 1 << 40 | 1, "Be")
@test ss == "FooBear"
@test ss.v == ["Foo", "Be", "ar"]

# Replace whole fragment
splice!(ss, 1 << 40 | 1, 1 << 40 | 2, "C")
@test ss == "FooCar"
@test ss.v == ["Foo", "C", "ar"]

# Replace two whole fragments
ss = SS("Foo", "XXX", "YYY", "Bar")
splice!(ss, 1 << 40 | 1, 2 << 40 | 3, "_")
@test ss == "Foo_Bar"
@test ss.v == ["Foo", "_", "Bar"]

# Replace three whole fragments
ss = SS("Foo", "XXX", "YYY", "Bar")
splice!(ss, 1 << 40 | 1, 3 << 40 | 3, "_")
@test ss == "Foo_"
@test ss.v == ["Foo", "_"]

# Replace all fragments
ss = SS("Foo", "XXX", "YYY", "Bar")
splice!(ss, 1 : 3 << 40 | 3, "_")
@test ss == "_"
@test ss.v == ["_"]

# Replace all fragments with nothing
ss = SS("Foo", "XXX", "YYY", "Bar")
splice!(ss, 1 , lastindex(ss), "")
@test ss == ""
@test ss.v == []

ss = SS("AAA", "BBB", "CCC")
i = findfirst(equalto('B'), ss)
splice!(ss, i , i+2, "")
@test ss == "AAACCC"
@test ss.v == ["AAA", "CCC"]

# Replace two whole fragments and part of another
ss = SS("Foo", "XXX", "YYY", "Bar")
splice!(ss, 1 << 40 | 1, 3 << 40 | 2, "u")
@test ss == "Foour"
@test ss.v == ["Foo", "u", "r"]

# Replace fragment suffix
ss = SS("Foo", "Bar")
splice!(ss, 3, 3, "g")
@test ss == "FogBar"
@test ss.v == ["Fo", "g", "Bar"]

# Replace fragment suffix and prefix
ss = SS("Foo", "Bar")
splice!(ss, 3, 1 << 40 | 2, "lde")
@test ss == "Folder"
@test ss.v == ["Fo", "lde", "r"]

# Replace fragment suffix and whole fragment and prefix
ss = SS("Foo", "XXX", "Bar")
splice!(ss, 3, 2 << 40 | 2, "lde")
@test ss == "Folder"
@test ss.v == ["Fo", "lde", "r"]

# Replace fragment suffix and whole fragment and prefix with multiple others
ss = SS("Foo", "XXX", "Bar")
splice!(ss, 2, 2 << 40 | 2, ["w", "oooo", "aaaaaa", "rr"])
@test ss == "Fwooooaaaaaarrr"
@test ss.v == ["F", "w", "oooo", "aaaaaa", "rr", "r"]

ss = SS("Foo", "XXX", "Bar")
splice!(ss, 2, 2 << 40 | 2, SS(SS("w", "oooo"), "aaaaaa", "rr"))
@test ss == "Fwooooaaaaaarrr"
@test ss.v == ["F", "w", "oooo", "aaaaaa", "rr", "r"]

ss = SS("Foo", "XXX", "Bar")
splice!(ss, 2, 2 << 40 | 2, [SS("w", "oooo"), "aaaaaa", SS("rr")])
@test ss == "Fwooooaaaaaarrr"
@test String(ss) == "Fwooooaaaaaarrr"
@test ss.v == ["F", "w", "oooo", "aaaaaa", "rr", "r"]


ss = SS(["Hello", " ", "world", "!"])
@test ss == "Hello world!"
@test String(ss) == "Hello world!"

ss = SS("xxxx", "Hello", " ", "world", "!", "yyyy")
@test SubString(ss, findfirst(equalto('l'), ss),
                    findfirst(equalto('r'), ss)) == "llo wor"

sss = SubString(ss, findfirst(equalto('l'), ss),
                    findfirst(equalto('r'), ss))
@test sss isa SubString{SS}

ss = SS("AAA", sss, "BBB")
@test ss.v == ["AAA", "llo", " ", "wor", "BBB"]

ss = SS(["Hello", " ", "world", "!"])
@test ss == "Hello world!"

i = 0 << 40 | 0 ; @test thisind(ss, i) == i     ; @test !isvalid(ss, i) ; @test nextind(ss, i) == i + 1
i = 0 << 40 | 1 ; @test thisind(ss, i) == i     ; @test  isvalid(ss, i) ; @test nextind(ss, i) == i + 1       ; @test prevind(ss, i) == i - 1       ; @test codeunit(ss, i) == UInt8('H')
i = 0 << 40 | 2 ; @test thisind(ss, i) == i     ; @test  isvalid(ss, i) ; @test nextind(ss, i) == i + 1       ; @test prevind(ss, i) == i - 1       ; @test codeunit(ss, i) == UInt8('e')
i = 0 << 40 | 3 ; @test thisind(ss, i) == i     ; @test  isvalid(ss, i) ; @test nextind(ss, i) == i + 1       ; @test prevind(ss, i) == i - 1       ; @test codeunit(ss, i) == UInt8('l')
i = 0 << 40 | 4 ; @test thisind(ss, i) == i     ; @test  isvalid(ss, i) ; @test nextind(ss, i) == i + 1       ; @test prevind(ss, i) == i - 1       ; @test codeunit(ss, i) == UInt8('l')
i = 0 << 40 | 5 ; @test thisind(ss, i) == i     ; @test  isvalid(ss, i) ; @test nextind(ss, i) == 1 << 40 | 1 ; @test prevind(ss, i) == i - 1       ; @test codeunit(ss, i) == UInt8('o')
i = 1 << 40 | 1 ; @test thisind(ss, i) == i     ; @test  isvalid(ss, i) ; @test nextind(ss, i) == 2 << 40 | 1 ; @test prevind(ss, i) == 0 << 40 | 5 ; @test codeunit(ss, i) == UInt8(' ')
i = 2 << 40 | 1 ; @test thisind(ss, i) == i     ; @test  isvalid(ss, i) ; @test nextind(ss, i) == i + 1       ; @test prevind(ss, i) == 1 << 40 | 1 ; @test codeunit(ss, i) == UInt8('w')
i = 2 << 40 | 2 ; @test thisind(ss, i) == i     ; @test  isvalid(ss, i) ; @test nextind(ss, i) == i + 1       ; @test prevind(ss, i) == i - 1       ; @test codeunit(ss, i) == UInt8('o')
i = 2 << 40 | 3 ; @test thisind(ss, i) == i     ; @test  isvalid(ss, i) ; @test nextind(ss, i) == i + 1       ; @test prevind(ss, i) == i - 1       ; @test codeunit(ss, i) == UInt8('r')
i = 2 << 40 | 4 ; @test thisind(ss, i) == i     ; @test  isvalid(ss, i) ; @test nextind(ss, i) == i + 1       ; @test prevind(ss, i) == i - 1       ; @test codeunit(ss, i) == UInt8('l')
i = 2 << 40 | 5 ; @test thisind(ss, i) == i     ; @test  isvalid(ss, i) ; @test nextind(ss, i) == 3 << 40 | 1 ; @test prevind(ss, i) == i - 1       ; @test codeunit(ss, i) == UInt8('d')
i = 3 << 40 | 1 ; @test thisind(ss, i) == i     ; @test  isvalid(ss, i) ; @test nextind(ss, i) == i + 1       ; @test prevind(ss, i) == 2 << 40 | 5 ; @test codeunit(ss, i) == UInt8('!')
i = 3 << 40 | 2 ; @test thisind(ss, i) == i     ; @test !isvalid(ss, i)                                       ; @test prevind(ss, i) == i - 1
                  @test ncodeunits(ss) == 3 << 40 | 1
                  @test length(ss) == 12
                  @test length(ss,           1, 3 << 40 | 1) == 12
                  @test length(ss,           2, 2 << 40 | 5) == 10
                  @test length(ss,           3, 2 << 40 | 4) == 8
                  @test length(ss,           4, 2 << 40 | 3) == 6
                  @test length(ss,           5, 2 << 40 | 2) == 4
                  @test length(ss, 1 << 40 | 1, 2 << 40 | 1) == 2
                  @test length(ss, 1 << 40 | 1, 1 << 40 | 1) == 1
                  @test length(ss, 1 << 40 | 1,           5) == 0


ss = SS(["\u1234x", "x\u1234"])
@test ss == "ሴxxሴ"

i = 0 << 40 | 0 ; @test thisind(ss, i) == i     ; @test !isvalid(ss, i) ; @test nextind(ss, i) == i + 1
i = 0 << 40 | 1 ; @test thisind(ss, i) == i     ; @test  isvalid(ss, i) ; @test nextind(ss, i) == i + 3
i = 0 << 40 | 2 ; @test thisind(ss, i) == i - 1 ; @test !isvalid(ss, i) ; @test nextind(ss, i) == i + 2
i = 0 << 40 | 3 ; @test thisind(ss, i) == i - 2 ; @test !isvalid(ss, i) ; @test nextind(ss, i) == i + 1
i = 0 << 40 | 4 ; @test thisind(ss, i) == i     ; @test  isvalid(ss, i) ; @test nextind(ss, i) == 1 << 40 | 1
i = 1 << 40 | 1 ; @test thisind(ss, i) == i     ; @test  isvalid(ss, i) ; @test nextind(ss, i) == i + 1
i = 1 << 40 | 2 ; @test thisind(ss, i) == i     ; @test  isvalid(ss, i) ; @test nextind(ss, i) == i + 3
i = 1 << 40 | 3 ; @test thisind(ss, i) == i - 1 ; @test !isvalid(ss, i) ; @test nextind(ss, i) == i + 2
i = 1 << 40 | 4 ; @test thisind(ss, i) == i - 2 ; @test !isvalid(ss, i) ; @test nextind(ss, i) == i + 1
i = 1 << 40 | 5 ; @test thisind(ss, i) == i     ; @test !isvalid(ss, i)
                  @test ncodeunits(ss) == 1 << 40 | 4
                  @test length(ss) == 4


ss = SS(["x\u1234", "\u1234x"])
@test ss == "xሴሴx"

i = 0 << 40 | 0 ; @test thisind(ss, i) == i     ; @test !isvalid(ss, i) ; @test nextind(ss, i) == i + 1
i = 0 << 40 | 1 ; @test thisind(ss, i) == i     ; @test  isvalid(ss, i) ; @test nextind(ss, i) == i + 1
i = 0 << 40 | 2 ; @test thisind(ss, i) == i     ; @test  isvalid(ss, i) ; @test nextind(ss, i) == 1 << 40 | 1
i = 0 << 40 | 3 ; @test thisind(ss, i) == i - 1 ; @test !isvalid(ss, i) ; @test nextind(ss, i) == 1 << 40 | 1
i = 0 << 40 | 4 ; @test thisind(ss, i) == i - 2 ; @test !isvalid(ss, i) ; @test nextind(ss, i) == 1 << 40 | 1
i = 1 << 40 | 1 ; @test thisind(ss, i) == i     ; @test  isvalid(ss, i) ; @test nextind(ss, i) == i + 3
i = 1 << 40 | 2 ; @test thisind(ss, i) == i - 1 ; @test !isvalid(ss, i) ; @test nextind(ss, i) == i + 2
i = 1 << 40 | 3 ; @test thisind(ss, i) == i - 2 ; @test !isvalid(ss, i) ; @test nextind(ss, i) == i + 1
i = 1 << 40 | 4 ; @test thisind(ss, i) == i     ; @test  isvalid(ss, i) ; @test nextind(ss, i) == i + 1
i = 1 << 40 | 5 ; @test thisind(ss, i) == i     ; @test !isvalid(ss, i)
                  @test ncodeunits(ss) == 1 << 40 | 4
                  @test length(ss) == 4


ss = SS("one", "two", "three")
@test 'o' in ss
@test 'n' in ss
@test 'e' in ss
@test 't' in ss
@test 'w' in ss
@test 'o' in ss
@test 'h' in ss
@test 'r' in ss
i = findfirst(equalto('w'), ss)
@test ss[i] == 'w'


ss = SS("one", "two", "three")
cu = LazyJSON.SplicedStrings.densecodeunits(ss)

@test  cu[1] == UInt8('o')
@test  cu[2] == UInt8('n')
@test  cu[3] == UInt8('e')
@test  cu[4] == UInt8('t')
@test  cu[5] == UInt8('w')
@test  cu[6] == UInt8('o')
@test  cu[7] == UInt8('t')
@test  cu[8] == UInt8('h')
@test  cu[9] == UInt8('r')
@test cu[10] == UInt8('e')
@test cu[11] == UInt8('e')

ncu = LazyJSON.SplicedStrings.nextcodeunit

@test ncu(ss, 0) == (1, UInt8('o'))
@test ncu(ss, 1) == (2, UInt8('n'))
@test ncu(ss, 2) == (3, UInt8('e'))
@test ncu(ss, 3) == (1 << 40 | 1, UInt8('t'))


end # @testset "SplicedString"