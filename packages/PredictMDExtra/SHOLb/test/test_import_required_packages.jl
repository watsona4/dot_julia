import Pkg # stdlib
import PredictMDExtra
import Test # stdlib

package_list = PredictMDExtra._package_list()

for p in package_list
    try
        eval(
            Base.Meta.parse(
                string(
                    "import ",
                    p,
                    ),
                ),
            )
    catch e
        @error("Ignoring exception: ", e,)
    end
end
