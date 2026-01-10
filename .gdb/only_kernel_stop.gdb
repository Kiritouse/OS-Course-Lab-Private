define hook-stop
  if (($pc & 0xFFFF000000000000) == 0xFFFF000000000000)
    printf "PC into high addr : %p\n", $pc
  else
    continue
  end
end

document hook-stop
end

define disable_only_kernel_stop
  define hook-stop
  end
end
