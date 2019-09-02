not_LoadError(x::LoadError) = x.error
not_LoadError(x) = x

macro test_error(testee, tester)
    quote
        ($(esc(tester)))(
            try
                $(esc(testee))
            catch err
               $not_LoadError(err)
            end)
    end
end
