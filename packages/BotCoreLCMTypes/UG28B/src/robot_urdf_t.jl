mutable struct robot_urdf_t <: LCMType
    utime::Int64
    robot_name::String
    urdf_xml_string::String

    left_hand::Int8
    right_hand::Int8
end

@lcmtypesetup(robot_urdf_t)
