" Test Vim9 enums

source check.vim
import './vim9.vim' as v9

" Test for parsing an enum definition
def Test_enum_parse()
  # enum supported only in a Vim9 script
  var lines =<< trim END
    enum Foo
    endenum
  END
  v9.CheckSourceFailure(lines, 'E1414: Enum can only be defined in Vim9 script', 1)

  # First character in an enum name should be capitalized.
  lines =<< trim END
    vim9script
    enum foo
    endenum
  END
  v9.CheckSourceFailure(lines, 'E1415: Enum name must start with an uppercase letter: foo', 2)

  # Only alphanumeric characters are supported in an enum name
  lines =<< trim END
    vim9script
    enum Foo@bar
    endenum
  END
  v9.CheckSourceFailure(lines, 'E488: Trailing characters: Foo@bar', 2)

  # Unsupported keyword (instead of enum)
  lines =<< trim END
    vim9script
    noenum Something
    endenum
  END
  v9.CheckSourceFailure(lines, 'E492: Not an editor command: noenum Something', 2)

  # Only the complete word "enum" should be recognized
  lines =<< trim END
    vim9script
    enums Something
    endenum
  END
  v9.CheckSourceFailure(lines, 'E492: Not an editor command: enums Something', 2)

  # The complete "endenum" should be specified.
  lines =<< trim END
    vim9script
    enum Something
    enden
  END
  v9.CheckSourceFailure(lines, 'E1065: Command cannot be shortened: enden', 3)

  # Only the complete word "endenum" should be recognized
  lines =<< trim END
    vim9script
    enum Something
    endenums
  END
  v9.CheckSourceFailure(lines, 'E1418: Missing :endenum', 4)

  # Additional words after "endenum"
  lines =<< trim END
    vim9script
    enum Something
    endenum school's out
  END
  v9.CheckSourceFailure(lines, "E488: Trailing characters: school's out", 3)

  # Additional commands after "endenum"
  lines =<< trim END
    vim9script
    enum Something
    endenum | echo 'done'
  END
  v9.CheckSourceFailure(lines, "E488: Trailing characters: | echo 'done'", 3)

  # Try to define an enum with the same name as an existing variable
  lines =<< trim END
    vim9script
    var Something: list<number> = [1]
    enum Something
    endenum
  END
  v9.CheckSourceFailure(lines, 'E1041: Redefining script item: "Something"', 3)

  # Space before "=" in an enum value
  lines =<< trim END
    vim9script
    enum Foo
      first
      second= 20
    endenum
  END
  v9.CheckSourceFailure(lines, "E1004: White space required before and after '='", 4)

  # Space after "=" in an enum value
  lines =<< trim END
    vim9script
    enum Foo
      first
      second =20
    endenum
  END
  v9.CheckSourceFailure(lines, "E1004: White space required before and after '='", 4)

  # Unsupported special character following enum name
  lines =<< trim END
    vim9script
    enum Foo
      first
      second : 20
    endenum
  END
  v9.CheckSourceFailure(lines, "E398: Missing '=': second : 20", 4)

  # Missing number after '='
  lines =<< trim END
    vim9script
    enum Foo
      first
      second = 
    endenum
  END
  v9.CheckSourceFailure(lines, 'E15: Invalid expression: ""', 4)

  # Invalid value type after '='
  lines =<< trim END
    vim9script
    enum Foo
      first
      second = []
    endenum
  END
  v9.CheckSourceFailure(lines, 'E521: Number required after =', 4)

  # Use a comma after name
  lines =<< trim END
    vim9script
    enum Foo

      # first
      first,
      second
    endenum
  END
  v9.CheckSourceFailure(lines, "E398: Missing '=': first,", 5)

  # Use a '=='
  lines =<< trim END
    vim9script
    enum Foo
      first == 1
    endenum
  END
  v9.CheckSourceFailure(lines, "E1004: White space required before and after '=' at \"first == 1\"", 3)
enddef

def Test_basic_enum()
  # Declare a simple enum and check the values
  var lines =<< trim END
    vim9script
    enum Foo
      apple = 10
      orange = 20
    endenum
    assert_equal(10, Foo.apple)
    assert_equal(20, Foo.orange)
  END
  v9.CheckSourceSuccess(lines)

  # Use a variable of type enum
  lines =<< trim END
    vim9script
    enum Foo
      apple = 10
      orange = 20
    endenum
    var a: Foo = Foo.orange
    assert_equal(20, a)
  END
  v9.CheckSourceSuccess(lines)

  # Try assigning an unsupported value to an enum
  lines =<< trim END
    vim9script
    enum Foo
      apple = 10
      orange = 20
    endenum
    var a: Foo = 30
  END
  v9.CheckSourceFailure(lines, "E1420: Enum \"Foo\" doesn't support value 30", 6)

  # Try using a non-existing enum value
  lines =<< trim END
    vim9script
    enum Foo
      apple = 10
      orange = 20
    endenum
    assert_equal(30, Foo.pear)
  END
  v9.CheckSourceFailure(lines, 'E1419: Enum "Foo" doesn''t support item "pear"', 6)

  # Try assigning to an enum
  lines =<< trim END
    vim9script
    enum Foo
      apple = 10
    endenum
    Foo.apple = 20
  END
  v9.CheckSourceFailure(lines, 'E1203: Dot not allowed after a enum: Foo.apple = 20', 5)

  # Enum function argument
  lines =<< trim END
    vim9script
    enum Foo
      apple = 10
      orange = 20
    endenum
    def Fn(a: Foo): Foo
      return a
    enddef
    assert_equal(10, Fn(Foo.apple))
    assert_equal(20, Fn(20))
  END
  v9.CheckSourceSuccess(lines)
enddef

" vim: ts=8 sw=2 sts=2 expandtab tw=80 fdm=marker
