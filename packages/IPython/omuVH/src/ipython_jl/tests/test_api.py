def test_eval(julia):
    assert julia.eval("123456789") == 123456789


def test_mutable_struct(julia):
    struct = julia.eval("""Base.eval(Module(), quote
    mutable struct Spam
        egg
    end
    Spam(123)
    end)""")
    assert julia.getattr(struct, "egg") == 123
    assert julia.setattr(struct, "egg", 456) is None
    assert julia.getattr(struct, "egg") == 456


def test_mutate_main(julia):
    scope = julia.eval("Main")
    assert julia.setattr(scope, "spam", 789) is None
    assert julia.getattr(scope, "spam") == 789
    assert julia.eval("Main.spam") == 789
