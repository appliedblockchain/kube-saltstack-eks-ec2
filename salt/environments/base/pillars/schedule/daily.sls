schedule:
  sync_all_daily:
    function: saltutil.sync_all
    hours: 24
    splay: 3600
    maxrunning: 1

  # Highstate disabled until we're confident enough to use it
  # highstate:
  #   function: state.highstate
  #   hours: 24
  #   splay: 3600
  #   maxrunning: 1
