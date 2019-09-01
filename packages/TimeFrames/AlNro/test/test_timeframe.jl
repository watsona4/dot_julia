using Dates
using TimeFrames
using TimeFrames: TimePeriodFrame, DatePeriodFrame 
using TimeFrames: period_step, _period_step
using TimeFrames: CustomTimeFrame, tonext


using Test

@testset "low level (period frame)" begin
    @testset "TimePeriodFrame" begin
        tf = TimePeriodFrame{Dates.Hour}()
        @test tf.period.value == 1
        @test tf.boundary == Begin

        tf = TimePeriodFrame{Dates.Hour}(5)
        @test tf.period.value == 5
        @test tf.boundary == Begin

        tf2 = TimePeriodFrame{Dates.Hour}(5)
        @test tf == tf2

        tf3 = TimePeriodFrame{Dates.Hour}(3)
        @test tf != tf3
    end

    @testset "DatePeriodFrame" begin
        tf = DatePeriodFrame{Dates.Month}()
        @test tf.period.value == 1
        @test tf.boundary == Begin

        tf = DatePeriodFrame{Dates.Month}(5)
        @test tf.period.value == 5
        @test tf.boundary == Begin

        tf2 = DatePeriodFrame{Dates.Month}(5)
        @test tf == tf2

        tf3 = DatePeriodFrame{Dates.Month}(3)
        @test tf != tf3
    end

    @testset "NoTimeFrame" begin
        tf = TimeFrame()
        @test typeof(tf) == NoTimeFrame

        tf2 = TimeFrame()
        @test tf == tf2
    end

    @testset "_period_step" begin
        @test _period_step(DateTime) == period_step
        @test _period_step(Date) == Dates.Day(1)
    end
end


@testset "high level" begin
    @testset "YearEnd, Minute, ..." begin
        tf = YearEnd()
        @test tf.period.value == 1

        @test YearEnd() == YearEnd()
        @test YearEnd() != YearBegin()
        @test YearEnd() != YearEnd(5)

        tf = TimeFrames.Minute()
        @test tf.period.value == 1

        tf = TimeFrames.Minute(15)
        @test tf.period.value == 15

        tf1 = TimeFrames.Minute(15)
        tf2 = TimeFrames.Minute(15)
        @test tf1 == tf2

        tf1 = TimeFrames.Minute(15)
        tf2 = TimeFrames.Minute(30)
        @test tf1 != tf2
    end

    @testset "to string" begin
        tf = TimeFrames.Minute()
        @test String(tf) == "T"

        tf = TimeFrames.Minute(15)
        @test String(tf) == "15T"
    end


    @testset "parse" begin

        @testset "simple parse" begin
            tf = TimeFrame("15T")
            @test tf.period.value == 15
            @test typeof(tf) == TimeFrames.Minute

            tf = TimeFrame("T")
            @test tf.period.value == 1
            @test typeof(tf) == TimeFrames.Minute

            tf = TimeFrame("15Min")
            @test tf.period.value == 15
            @test String(tf) == "15T"
            @test typeof(tf) == TimeFrames.Minute

            tf = TimeFrame("5H")
            @test tf.period.value == 5
            @test typeof(tf) == TimeFrames.Hour
        end

        @testset "NoTimeFrame parse" begin
            tf = TimeFrame("")
            @test typeof(tf) == NoTimeFrame
            @test NoTimeFrame() == NoTimeFrame(1,2,3)
        end

        @testset "boundary" begin
            tf = TimeFrame("3A")
            @test tf == YearEnd(3)
            @test tf.period == Dates.Year(3)
            @test tf.boundary == End

            tf = TimeFrame("3AS")
            @test tf == YearBegin(3)
            @test tf.period == Dates.Year(3)
            #@test tf.boundary == Begin  # ToFix

            tf = TimeFrame("3M")
            @test tf == MonthEnd(3)
            @test tf.period == Dates.Month(3)
            @test tf.boundary == End

            tf = TimeFrame("3MS")
            @test tf == MonthBegin(3)
            @test tf.period == Dates.Month(3)
            #@test tf.boundary == Begin  # ToFix
        end

        @testset "*" begin
            @testset "TimePeriodFrame * n / n * TimePeriodFrame" begin
                tf = TimeFrame("2H")
                @test tf * 3 == TimeFrame("6H")

                tf = TimeFrame("2H")
                @test 3 * tf == TimeFrame("6H")
            end
            @testset "DatePeriodFrame * n / n * DatePeriodFrame" begin
                tf = TimeFrame("2M")
                @test tf * 3 == TimeFrame("6M")

                tf = TimeFrame("2M")
                @test 3 * tf == TimeFrame("6M")
            end
        end

        @testset "grouper/apply" begin
            @test apply(MonthEnd(), Date(2010, 2, 20)) == Date(2010, 2, 28)
            @test apply(MonthEnd(), DateTime(2010, 2, 20)) == DateTime(2010, 3, 1) - period_step

            d = Date(2016, 7, 20)
            dt = DateTime(2016, 7, 20, 13, 24, 35, 245)

            tf = TimeFrame(dt -> floor(dt, Dates.Minute(15)))  # custom TimeFrame with lambda function as DateTime grouper
            @test apply(tf, dt) == DateTime(2016, 7, 20, 13, 15, 0, 0)
            @test typeof(tf) == CustomTimeFrame

            tf = TimeFrame(Dates.Minute(15))  # TimePeriodFrame using TimePeriod
            @test apply(tf, dt) == DateTime(2016, 7, 20, 13, 15, 0, 0)

            tf = TimeFrame(Dates.Day(1))  # TimePeriodFrame using DatePeriod
            @test apply(tf, dt) == DateTime(2016, 7, 20, 0, 0, 0, 0)

            tf = YearBegin()
            #@test apply(tf, dt) == DateTime(2016, 1, 1, 0, 0, 0, 0)
            @test apply(tf, dt) == Date(2016, 1, 1)
            #@test typeof(f_group(dt)) == Date

            #tf = YearEnd(boundary=End)
            #@test apply(tf, dt) == DateTime(2016, 1, 1, 0, 0, 0, 0)
            #@test apply(tf, dt) == Date(2016, 1, 1)

            tf = MonthBegin()
            #@test apply(tf, dt) == DateTime(2016, 7, 1, 0, 0, 0, 0)
            @test apply(tf, dt) == Date(2016, 7, 1)

            tf = TimeFrames.Week()
            #@test apply(tf, dt) == DateTime(2016, 7, 18, 0, 0, 0, 0)
            @test apply(tf, dt) == Date(2016, 7, 18)

            tf = TimeFrames.Day()
            #@test apply(tf, dt) == DateTime(2016, 7, 20, 0, 0, 0, 0)
            @test apply(tf, dt) == Date(2016, 7, 20)

            tf = TimeFrames.Hour()
            @test apply(tf, dt) == DateTime(2016, 7, 20, 13, 0, 0, 0)

            tf = TimeFrames.Minute()
            @test apply(tf, dt) == DateTime(2016, 7, 20, 13, 24, 0, 0)

            tf = TimeFrames.Second()
            @test apply(tf, dt) == DateTime(2016, 7, 20, 13, 24, 35, 0)

            tf = TimeFrames.Millisecond()
            @test apply(tf, dt) == DateTime(2016, 7, 20, 13, 24, 35, 245)

            tf = YearBegin(10)
            @test apply(tf, dt) == DateTime(2010, 1, 1, 0, 0, 0, 0)

            tf = YearEnd(10)
            @test apply(tf, d) == DateTime(2019, 12, 31)
            @test apply(tf, dt) == DateTime(2020, 1, 1) - period_step

            tf = TimeFrames.Minute(15)
            @test apply(tf, dt) == DateTime(2016, 7, 20, 13, 15, 0, 0)
        end

        @testset "tonext" begin
            dt = DateTime(2010, 1, 1, 10, 30)
            @test tonext(TimeFrame("2H"), dt) == DateTime(2010, 1, 1, 12, 0)

            dt = DateTime(2010, 1, 1, 0, 0)  # ; same=false
            @test tonext(TimeFrame("2H"), dt) == DateTime(2010, 1, 1, 2, 0)

            dt = DateTime(2010, 1, 1, 0, 0)
            @test tonext(TimeFrame("2H"), dt; same=true) == DateTime(2010, 1, 1, 0, 0)

            dt = DateTime(2010, 1, 1, 10, 30)
            @test tonext(TimeFrame("1D"), dt) == DateTime(2010, 1, 2, 0, 0)

            dt = DateTime(2010, 1, 1, 10, 30)
            @test tonext(TimeFrame("1MS"), dt) == DateTime(2010, 2, 1, 0, 0)

            dt = DateTime(2010, 1, 1, 10, 30)
            @test tonext(TimeFrame("1M"), dt) == DateTime(2010, 2, 1) - period_step

            dt = DateTime(2010, 6, 5, 10, 30)
            @test tonext(TimeFrame("1A"), dt) == DateTime(2011, 1, 1) - period_step

            dt = DateTime(2010, 6, 5, 10, 30)
            @test tonext(TimeFrame("1AS"), dt) == DateTime(2011, 1, 1)

          end
        
        @testset "range" begin
            dt1 = DateTime(2010, 1, 1, 20)
            dt2 = DateTime(2010, 1, 14, 16)
            tf = Dates.Day(1)
            rng = range(dt1, TimeFrame(tf), dt2)
            @test rng[1] == DateTime(2010, 1, 1)
            @test rng[end] == DateTime(2010, 1, 14)

            rng = range(dt1, TimeFrame(tf), dt2, apply_tf=false)
            @test rng[1] == DateTime(2010, 1, 1, 20)
            @test rng[end] == DateTime(2010, 1, 13, 20)

            tf = Dates.Day(1)
            N = 5
            rng = range(dt1, TimeFrame(tf), N)
            @test length(rng) == N
            @test rng[1] == DateTime(2010, 1, 1, 20)
            @test rng[end] == DateTime(2010, 1, 5, 20)

            tf = Dates.Day(1)
            N = 5
            rng = range(TimeFrame(tf), dt2, N)
            @test length(rng) == N
            @test rng[end] == DateTime(2010, 1, 13, 16)
            @test rng[1] == DateTime(2010, 1, 9, 16)

            dt1 = DateTime(2010, 1, 1, 20)
            dt2 = DateTime(2010, 1, 14, 16)
            tf = NoTimeFrame()
            rng = range(dt1, tf, dt2)
            @test length(rng) == 1
            @test rng[1] == dt1
        end


        @testset "@tf" begin
            @test tf"1T" == TimeFrame("1T")
            @test tf"1M" == TimeFrame("M")
        end  # @testset "@tf
    end


    @testset "+" begin
        d = Date(2017, 12, 1)
        let tf = tf"1A", ans = Date(2018, 12, 1)
            @test isdefined(tf, :period)
            @test d + tf == ans
            @test tf + d == ans
            @inferred d + tf
            @inferred tf + d
        end

        let tf = tf"1AS", ans = Date(2018, 12, 1)
            @test isdefined(tf, :period)
            @test d + tf == ans
            @test tf + d == ans
            @inferred d + tf
            @inferred tf + d
        end

        let tf = tf"1M", ans = Date(2018, 1, 1)
            @test isdefined(tf, :period)
            @test d + tf == ans
            @test tf + d == ans
            @inferred d + tf
            @inferred tf + d
        end

        let tf = tf"1MS", ans = Date(2018, 1, 1)
            @test isdefined(tf, :period)
            @test d + tf == ans
            @test tf + d == ans
            @inferred d + tf
            @inferred tf + d
        end

        let tf = tf"1W", ans = Date(2017, 12, 8)
            @test isdefined(tf, :period)
            @test d + tf == ans
            @test tf + d == ans
            @inferred d + tf
            @inferred tf + d
        end

        let tf = tf"1D", ans = Date(2017, 12, 2)
            @test isdefined(tf, :period)
            @test d + tf == ans
            @test tf + d == ans
            @inferred d + tf
            @inferred tf + d
        end

        let tf = tf"1H", ans = DateTime(2017, 12, 1, 1, 0, 0, 0)
            @test isdefined(tf, :period)
            @test d + tf == ans
            @test tf + d == ans
            @inferred d + tf
            @inferred tf + d
        end

        let tf = tf"1T", ans = DateTime(2017, 12, 1, 0, 1, 0, 0)
            @test isdefined(tf, :period)
            @test d + tf == ans
            @test tf + d == ans
            @inferred d + tf
            @inferred tf + d
        end

        let tf = tf"1S", ans = DateTime(2017, 12, 1, 0, 0, 1, 0)
            @test isdefined(tf, :period)
            @test d + tf == ans
            @test tf + d == ans
            @inferred d + tf
            @inferred tf + d
        end

        let tf = tf"1L", ans = DateTime(2017, 12, 1, 0, 0, 0, 1)
            @test isdefined(tf, :period)
            @test d + tf == ans
            @test tf + d == ans
            @inferred d + tf
            @inferred tf + d
        end

        d = Dates.Time(0, 1, 2, 3)
        let tf = tf"1H", ans = Dates.Time(1, 1, 2, 3)
            @test isdefined(tf, :period)
            @test d + tf == ans
            @test tf + d == ans
            @inferred d + tf
            @inferred tf + d
        end

        let tf = tf"1T", ans = Dates.Time(0, 2, 2, 3)
            @test isdefined(tf, :period)
            @test d + tf == ans
            @test tf + d == ans
            @inferred d + tf
            @inferred tf + d
        end

        let tf = tf"1S", ans = Dates.Time(0, 1, 3, 3)
            @test isdefined(tf, :period)
            @test d + tf == ans
            @test tf + d == ans
            @inferred d + tf
            @inferred tf + d
        end

        let tf = tf"1L", ans = Dates.Time(0, 1, 2, 4)
            @test isdefined(tf, :period)
            @test d + tf == ans
            @test tf + d == ans
            @inferred d + tf
            @inferred tf + d
        end

        d = Dates.Time(0, 1, 2, 3)
        @test_throws InexactError d + tf"1A"
        @test_throws InexactError d + tf"1AS"
        @test_throws InexactError d + tf"1M"
        @test_throws InexactError d + tf"1MS"
        @test_throws InexactError d + tf"1W"
        @test_throws InexactError d + tf"1D"

        @test_throws InexactError tf"1A"  + d
        @test_throws InexactError tf"1AS" + d
        @test_throws InexactError tf"1M"  + d
        @test_throws InexactError tf"1MS" + d
        @test_throws InexactError tf"1W"  + d
        @test_throws InexactError tf"1D"  + d
    end  # @testset "+"


    @testset "-" begin
        d = Date(2017, 12, 1)
        let tf = tf"1A"
            @test isdefined(tf, :period)
            @test d - tf == Date(2016, 12, 1)
            @inferred d - tf
        end

        let tf = tf"1AS"
            @test isdefined(tf, :period)
            @test d - tf == Date(2016, 12, 1)
            @inferred d - tf
        end

        let tf = tf"1M"
            @test isdefined(tf, :period)
            @test d - tf == Date(2017, 11, 1)
            @inferred d - tf
        end

        let tf = tf"1MS"
            @test isdefined(tf, :period)
            @test d - tf == Date(2017, 11, 1)
            @inferred d - tf
        end

        let tf = tf"1W"
            @test isdefined(tf, :period)
            @test d - tf == Date(2017, 11, 24)
            @inferred d - tf
        end

        let tf = tf"1D"
            @test isdefined(tf, :period)
            @test d - tf == Date(2017, 11, 30)
            @inferred d - tf
        end

        let tf = tf"1H"
            @test isdefined(tf, :period)
            @test d - tf == DateTime(2017, 11, 30, 23, 0, 0, 0)
            @inferred d - tf
        end

        let tf = tf"1T"
            @test isdefined(tf, :period)
            @test d - tf == DateTime(2017, 11, 30, 23, 59, 0, 0)
            @inferred d - tf
        end

        let tf = tf"1S"
            @test isdefined(tf, :period)
            @test d - tf == DateTime(2017, 11, 30, 23, 59, 59, 0)
            @inferred d - tf
        end

        let tf = tf"1L"
            @test isdefined(tf, :period)
            @test d - tf == DateTime(2017, 11, 30, 23, 59, 59, 999)
            @inferred d - tf
        end

        d = Dates.Time(0, 1, 2, 3)
        let tf = tf"1H"
            @test isdefined(tf, :period)
            @test d - tf == Dates.Time(23, 1, 2, 3)
            @inferred d - tf
        end

        let tf = tf"1T"
            @test isdefined(tf, :period)
            @test d - tf == Dates.Time(0, 0, 2, 3)
            @inferred d - tf
        end

        let tf = tf"1S"
            @test isdefined(tf, :period)
            @test d - tf == Dates.Time(0, 1, 1, 3)
            @inferred d - tf
        end

        let tf = tf"1L"
            @test isdefined(tf, :period)
            @test d - tf == Dates.Time(0, 1, 2, 2)
            @inferred d - tf
        end

        d = Dates.Time(0, 1, 2, 3)
        @test_throws InexactError d - tf"1A"
        @test_throws InexactError d - tf"1AS"
        @test_throws InexactError d - tf"1M"
        @test_throws InexactError d - tf"1MS"
        @test_throws InexactError d - tf"1W"
        @test_throws InexactError d - tf"1D"
    end  # @testset "-"
end  # @testset "high level"
