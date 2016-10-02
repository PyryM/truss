-- examples/13_criterror.t
--
-- has an error with no fallback to test error codes

function init()
    -- do nothing
end

function ohno()
    terra blah(input: &ThisTypeDoesntExist)
        return input.fakeField
    end
end

-- the weird spacing here is to test that error line numbering is correct

function yay()

    ohno()

end

function woo()

    yay()

end

function update()
    -- have an error
    woo()
end

function fallbackUpdate()
    x.x.x.x = 12
end
