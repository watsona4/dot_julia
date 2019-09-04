using Zomato
using Compat.Test

# More comprehensive tests needed!
@test typeof(Zomato.authenticate("apikey")) == Zomato.Auth