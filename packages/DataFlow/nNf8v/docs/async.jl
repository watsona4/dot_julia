function foo(username)
  @join begin
    account = login(username)
    last = getlastlogin(account)
    dms = getdms(account)
    who = getuser(account, dms[end])
    followers = publicinfo(username)[:followers]
  end

  # Do something with followers, last, who etc.
end

followers = @fork publicinfo(username)[:followers]
account = @fork login(username)
last = @fork getlastlogin(fetch(account))
dms = getdms(fetch(account))
who = getuser(fetch(account), dms[end])
fetchall(last, who, followers)
