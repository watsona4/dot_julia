datadir = "valkyrie"
valkyrie_examples_url = "https://raw.githubusercontent.com/rdeits/drake/eb1dc0ff1b263772e26e177566479c9d17571e7d/examples/valkyrie/"
urdfpath = "urdf/urdf/valkyrie_A_sim_drake_one_neck_dof_wide_ankle_rom.urdf"
meshpaths = ["urdf/model/meshes/arms/aj1_left.obj";
    "urdf/model/meshes/arms/aj1_right.obj";
    "urdf/model/meshes/arms/aj2_left.obj";
    "urdf/model/meshes/arms/aj2_right.obj";
    "urdf/model/meshes/arms/aj3_left.obj";
    "urdf/model/meshes/arms/aj3_right.obj";
    "urdf/model/meshes/arms/aj4_left.obj";
    "urdf/model/meshes/arms/aj4_right.obj";
    "urdf/model/meshes/arms/aj5_left.obj";
    "urdf/model/meshes/arms/aj5_right.obj";
    "urdf/model/meshes/arms/aj6_left.obj";
    "urdf/model/meshes/arms/aj6_right.obj";
    "urdf/model/meshes/arms/palm_left.obj";
    "urdf/model/meshes/arms/palm_right.obj";
    "urdf/model/meshes/fingers/indexj1_left.obj";
    "urdf/model/meshes/fingers/indexj1_right.obj";
    "urdf/model/meshes/fingers/indexj2_left.obj";
    "urdf/model/meshes/fingers/indexj2_right.obj";
    "urdf/model/meshes/fingers/indexj3_left.obj";
    "urdf/model/meshes/fingers/indexj3_right.obj";
    "urdf/model/meshes/fingers/middlej1_left.obj";
    "urdf/model/meshes/fingers/middlej1_right.obj";
    "urdf/model/meshes/fingers/middlej2_left.obj";
    "urdf/model/meshes/fingers/middlej2_right.obj";
    "urdf/model/meshes/fingers/middlej3_left.obj";
    "urdf/model/meshes/fingers/middlej3_right.obj";
    "urdf/model/meshes/fingers/pinkyj1_left.obj";
    "urdf/model/meshes/fingers/pinkyj1_right.obj";
    "urdf/model/meshes/fingers/pinkyj2_left.obj";
    "urdf/model/meshes/fingers/pinkyj2_right.obj";
    "urdf/model/meshes/fingers/pinkyj3_left.obj";
    "urdf/model/meshes/fingers/pinkyj3_right.obj";
    "urdf/model/meshes/fingers/thumbj1_left.obj";
    "urdf/model/meshes/fingers/thumbj1_right.obj";
    "urdf/model/meshes/fingers/thumbj2_left.obj";
    "urdf/model/meshes/fingers/thumbj2_right.obj";
    "urdf/model/meshes/fingers/thumbj3_left.obj";
    "urdf/model/meshes/fingers/thumbj3_right.obj";
    "urdf/model/meshes/fingers/thumbj4_left.obj";
    "urdf/model/meshes/fingers/thumbj4_right.obj";
    "urdf/model/meshes/head/head_multisense.obj";
    "urdf/model/meshes/head/head_multisense_no_visor.obj";
    "urdf/model/meshes/head/multisense_hokuyo.obj";
    "urdf/model/meshes/head/neckj1.obj";
    "urdf/model/meshes/head/neckj2.obj";
    "urdf/model/meshes/legs/foot.obj";
    "urdf/model/meshes/legs/lj1_left.obj";
    "urdf/model/meshes/legs/lj1_right.obj";
    "urdf/model/meshes/legs/lj2_left.obj";
    "urdf/model/meshes/legs/lj2_right.obj";
    "urdf/model/meshes/legs/lj3_left.obj";
    "urdf/model/meshes/legs/lj3_right.obj";
    "urdf/model/meshes/legs/lj4_left.obj";
    "urdf/model/meshes/legs/lj4_right.obj";
    "urdf/model/meshes/legs/lj5.obj";
    "urdf/model/meshes/multisense/head_camera.obj";
    "urdf/model/meshes/pelvis/pelvis.obj";
    "urdf/model/meshes/torso/torso.obj";
    "urdf/model/meshes/torso/torsopitch.obj";
    "urdf/model/meshes/torso/torsoyaw.obj"]

ispath(datadir) || mkpath(datadir)
download(valkyrie_examples_url * urdfpath, joinpath(datadir, "valkyrie.urdf"))

for meshpath in meshpaths
    meshdir, meshfilename = splitdir(meshpath)
    meshdir = joinpath(datadir, meshdir)
    ispath(meshdir) || mkpath(meshdir)
    download(valkyrie_examples_url * meshpath, joinpath(datadir, meshpath))
end
