@testset "Testing General submodule" begin

fnMeasBruker = "measurement_Bruker"
fnSMBruker = "systemMatrix_Bruker"
fnSM1DBruker = "systemMatrix1D_Bruker"
fnMeasV1 = "measurement_V1.mdf"
fnMeasV2 = "measurement_V2.mdf"
fnSMV1 = "systemMatrix_V1.mdf"
fnSMV2 = "systemMatrix_V2.mdf"
fnSMV3 = "systemMatrix_V3.mdf"
fnSM1DV1 = "systemMatrix1D_V1.mdf"
fnSM1DV2 = "systemMatrix1D_V2.mdf"

if !isdir(fnSMBruker)
  @info "download $fnSMBruker"
  HTTP.open("GET", "http://media.tuhh.de/ibi/"*fnSMBruker*".zip") do http
    open(fnSMBruker*".zip", "w") do file
        write(file, http)
    end
  end
  run(`unzip $(fnSMBruker).zip`)
end
if !isdir(fnMeasBruker)
  @info "download $fnMeasBruker"
  HTTP.open("GET", "http://media.tuhh.de/ibi/"*fnMeasBruker*".zip") do http
    open(fnMeasBruker*".zip", "w") do file
        write(file, http)
    end
  end
  run(`unzip $(fnMeasBruker).zip`)
end
if !isdir(fnSM1DBruker)
  @info "download $fnSM1DBruker"
  HTTP.open("GET", "http://media.tuhh.de/ibi/"*fnSM1DBruker*".zip") do http
    open(fnSM1DBruker*".zip", "w") do file
        write(file, http)
    end
  end
  run(`unzip $(fnSM1DBruker).zip`)
end


measBruker = MPIFile(fnMeasBruker)
@test typeof(measBruker) == BrukerFileMeas

saveasMDF(fnMeasV2, measBruker)#, frames=1:100) <- TODO test this

mdfv2 = MPIFile(fnMeasV2)
@test typeof(mdfv2) == MDFFileV2

for mdf in (measBruker,mdfv2)
  @info "Test $mdf"
  @test studyName(mdf) == "Wuerfelphantom"
  @test studyNumber(mdf) == 1
  @test studyDescription(mdf) == "n.a."
  @test studyTime(mdf) == DateTime( "2015-09-15T10:21:10.992" )
  @test studyUuid(mdf) == UUID("fe9635e0-7cfc-44eb-9f5a-585013a2cb51")

  @test experimentName(mdf) == "fuenf (E18)"
  @test experimentNumber(mdf) == 18
  @test experimentDescription(mdf) == "fuenf (E18)"
  @test experimentSubject(mdf) == "Wuerfelphantom"
  @test experimentIsSimulation(mdf) == false
  @test experimentIsCalibration(mdf) == false
  @test experimentUuid(mdf) == UUID("ef2110b5-cce8-4ca6-b041-38ea01254c47")

  @test scannerFacility(mdf) == "Universitätsklinikum Hamburg Eppendorf"
  @test scannerOperator(mdf) == "nmrsu"
  @test scannerManufacturer(mdf) == "Bruker/Philips"
  @test scannerName(mdf) == "Preclinical MPI System"
  @test scannerTopology(mdf) == "FFP"

  @test tracerName(mdf) == ["Resovist"]
  @test tracerBatch(mdf) == ["0"]
  @test tracerVendor(mdf) == ["n.a."]
  @test tracerVolume(mdf) == [0.0]
  @test tracerConcentration(mdf) == [0.5]
  @test tracerInjectionTime(mdf) == [DateTime("2015-09-15T11:17:23.011")]

  @test acqStartTime(mdf) == DateTime("2015-09-15T11:17:23.011")
  @test acqGradient(mdf)[:,:,1,1] == [-1.25 0 0; 0 -1.25 0;0 0 2.5]
  @test acqFramePeriod(mdf) == 6.528E-4
  @test acqNumPeriodsPerFrame(mdf) == 1
  @test acqOffsetFieldShift(mdf)[:,1,1] == [0.0; 0.0; -0.0]

  @test dfNumChannels(mdf) == 3
  @test dfWaveform(mdf) == "sine"
  @test dfStrength(mdf)[:,:,1] == [0.014 0.014 0.0]
  @test dfPhase(mdf)[:,:,1] == [1.5707963267948966 1.5707963267948966 1.5707963267948966]
  @test dfBaseFrequency(mdf) == 2500000.0
  @test dfDivider(mdf)[:,1] == [102; 96; 99]
  @test dfCycle(mdf) == 6.528E-4

  @test rxNumChannels(mdf) == 3
  @test rxBandwidth(mdf) == 1250000.0
  @test rxNumSamplingPoints(mdf) == 1632
  @test rxDataConversionFactor(mdf) == repeat([1.0, 0.0], outer=(1,rxNumChannels(mdf)))
  @test acqNumAverages(mdf) == 1

  @test acqNumFrames(mdf) == 500
  @test acqNumPeriodsPerFrame(mdf) == 1
  @test acqNumPeriods(mdf) == 500
  @test acqNumPatches(mdf) == 1
  @test acqNumPeriodsPerPatch(mdf) == 1

  @test size( measData(mdf) ) == (1632,3,1,500)
  @test size( measDataTDPeriods(mdf) ) == (1632,3,500)
  @test size( measDataTDPeriods(mdf, 101:200) ) == (1632,3,100)

  N = acqNumFrames(mdf)

  @test size(getMeasurements(mdf, numAverages=1,
              spectralLeakageCorrection=false)) == (1632,3,1,500)

  @test size(getMeasurements(mdf, numAverages=10,
              spectralLeakageCorrection=false)) == (1632,3,1,50)

  @test size(getMeasurements(mdf, numAverages=10, frames=1:100,
              spectralLeakageCorrection=true)) == (1632,3,1,10)

  @test size(getMeasurementsFD(mdf, numAverages=10, frames=1:100)) == (817,3,1,10)

  @test size(getMeasurementsFD(mdf, numAverages=10, frames=1:100, loadasreal=true)) == (1634,3,1,10)

  @test size(getMeasurementsFD(mdf,frequencies=1:10, numAverages=10)) == (10,1,50)

end



# Calibration File

smBruker = MPIFile(fnSMBruker)
@test typeof(smBruker) == BrukerFileCalib

saveasMDF(fnSMV2, smBruker)

smv2 = MPIFile(fnSMV2)
@test typeof(smv2) == MDFFileV2

smBrukerPretendToBeMeas = MPIFile(fnSMBruker, isCalib=false)
saveasMDF(fnSMV3, smBrukerPretendToBeMeas, applyCalibPostprocessing=true)

smv3 = MPIFile(fnSMV3)
@test typeof(smv3) == MDFFileV2

# Bruker specific test
@test rawDataLengthConsistent(smBruker)

for sm in (smBruker,smv2,smv3)
  @info "Test $sm"

  @test size( systemMatrixWithBG(sm) ) == (1959,817,3,1)
  @test size( systemMatrix(sm,1:10) ) == (1936,10)

  @test measIsFourierTransformed(sm) == true
  @test measIsTFCorrected(sm) == false
  @test measIsTransposed(sm) == true
  @test measIsBGCorrected(sm) == false
  @test measFramePermutation(sm) == [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 89, 88, 87, 86, 85, 84, 83, 82, 81, 80, 79, 78, 77, 76, 75, 74, 73, 72, 71, 70, 69, 68, 67, 66, 65, 64, 63, 62, 61, 60, 59, 58, 57, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 178, 177, 176, 175, 174, 173, 172, 171, 170, 169, 168, 167, 166, 165, 164, 163, 162, 161, 160, 159, 158, 157, 156, 155, 154, 153, 152, 151, 150, 149, 148, 147, 146, 145, 144, 143, 142, 141, 140, 139, 138, 137, 136, 135, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 267, 266, 265, 264, 263, 262, 261, 260, 259, 258, 257, 256, 255, 254, 253, 252, 251, 250, 249, 248, 247, 246, 245, 244, 243, 242, 241, 240, 239, 238, 237, 236, 235, 234, 233, 232, 231, 230, 229, 228, 227, 226, 225, 224, 269, 270, 271, 272, 273, 274, 275, 276, 277, 278, 279, 280, 281, 282, 283, 284, 285, 286, 287, 288, 289, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 302, 303, 304, 305, 306, 307, 308, 309, 310, 311, 312, 356, 355, 354, 353, 352, 351, 350, 349, 348, 347, 346, 345, 344, 343, 342, 341, 340, 339, 338, 337, 336, 335, 334, 333, 332, 331, 330, 329, 328, 327, 326, 325, 324, 323, 322, 321, 320, 319, 318, 317, 316, 315, 314, 313, 358, 359, 360, 361, 362, 363, 364, 365, 366, 367, 368, 369, 370, 371, 372, 373, 374, 375, 376, 377, 378, 379, 380, 381, 382, 383, 384, 385, 386, 387, 388, 389, 390, 391, 392, 393, 394, 395, 396, 397, 398, 399, 400, 401, 445, 444, 443, 442, 441, 440, 439, 438, 437, 436, 435, 434, 433, 432, 431, 430, 429, 428, 427, 426, 425, 424, 423, 422, 421, 420, 419, 418, 417, 416, 415, 414, 413, 412, 411, 410, 409, 408, 407, 406, 405, 404, 403, 402, 447, 448, 449, 450, 451, 452, 453, 454, 455, 456, 457, 458, 459, 460, 461, 462, 463, 464, 465, 466, 467, 468, 469, 470, 471, 472, 473, 474, 475, 476, 477, 478, 479, 480, 481, 482, 483, 484, 485, 486, 487, 488, 489, 490, 534, 533, 532, 531, 530, 529, 528, 527, 526, 525, 524, 523, 522, 521, 520, 519, 518, 517, 516, 515, 514, 513, 512, 511, 510, 509, 508, 507, 506, 505, 504, 503, 502, 501, 500, 499, 498, 497, 496, 495, 494, 493, 492, 491, 536, 537, 538, 539, 540, 541, 542, 543, 544, 545, 546, 547, 548, 549, 550, 551, 552, 553, 554, 555, 556, 557, 558, 559, 560, 561, 562, 563, 564, 565, 566, 567, 568, 569, 570, 571, 572, 573, 574, 575, 576, 577, 578, 579, 623, 622, 621, 620, 619, 618, 617, 616, 615, 614, 613, 612, 611, 610, 609, 608, 607, 606, 605, 604, 603, 602, 601, 600, 599, 598, 597, 596, 595, 594, 593, 592, 591, 590, 589, 588, 587, 586, 585, 584, 583, 582, 581, 580, 625, 626, 627, 628, 629, 630, 631, 632, 633, 634, 635, 636, 637, 638, 639, 640, 641, 642, 643, 644, 645, 646, 647, 648, 649, 650, 651, 652, 653, 654, 655, 656, 657, 658, 659, 660, 661, 662, 663, 664, 665, 666, 667, 668, 712, 711, 710, 709, 708, 707, 706, 705, 704, 703, 702, 701, 700, 699, 698, 697, 696, 695, 694, 693, 692, 691, 690, 689, 688, 687, 686, 685, 684, 683, 682, 681, 680, 679, 678, 677, 676, 675, 674, 673, 672, 671, 670, 669, 714, 715, 716, 717, 718, 719, 720, 721, 722, 723, 724, 725, 726, 727, 728, 729, 730, 731, 732, 733, 734, 735, 736, 737, 738, 739, 740, 741, 742, 743, 744, 745, 746, 747, 748, 749, 750, 751, 752, 753, 754, 755, 756, 757, 801, 800, 799, 798, 797, 796, 795, 794, 793, 792, 791, 790, 789, 788, 787, 786, 785, 784, 783, 782, 781, 780, 779, 778, 777, 776, 775, 774, 773, 772, 771, 770, 769, 768, 767, 766, 765, 764, 763, 762, 761, 760, 759, 758, 803, 804, 805, 806, 807, 808, 809, 810, 811, 812, 813, 814, 815, 816, 817, 818, 819, 820, 821, 822, 823, 824, 825, 826, 827, 828, 829, 830, 831, 832, 833, 834, 835, 836, 837, 838, 839, 840, 841, 842, 843, 844, 845, 846, 890, 889, 888, 887, 886, 885, 884, 883, 882, 881, 880, 879, 878, 877, 876, 875, 874, 873, 872, 871, 870, 869, 868, 867, 866, 865, 864, 863, 862, 861, 860, 859, 858, 857, 856, 855, 854, 853, 852, 851, 850, 849, 848, 847, 892, 893, 894, 895, 896, 897, 898, 899, 900, 901, 902, 903, 904, 905, 906, 907, 908, 909, 910, 911, 912, 913, 914, 915, 916, 917, 918, 919, 920, 921, 922, 923, 924, 925, 926, 927, 928, 929, 930, 931, 932, 933, 934, 935, 979, 978, 977, 976, 975, 974, 973, 972, 971, 970, 969, 968, 967, 966, 965, 964, 963, 962, 961, 960, 959, 958, 957, 956, 955, 954, 953, 952, 951, 950, 949, 948, 947, 946, 945, 944, 943, 942, 941, 940, 939, 938, 937, 936, 981, 982, 983, 984, 985, 986, 987, 988, 989, 990, 991, 992, 993, 994, 995, 996, 997, 998, 999, 1000, 1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011, 1012, 1013, 1014, 1015, 1016, 1017, 1018, 1019, 1020, 1021, 1022, 1023, 1024, 1068, 1067, 1066, 1065, 1064, 1063, 1062, 1061, 1060, 1059, 1058, 1057, 1056, 1055, 1054, 1053, 1052, 1051, 1050, 1049, 1048, 1047, 1046, 1045, 1044, 1043, 1042, 1041, 1040, 1039, 1038, 1037, 1036, 1035, 1034, 1033, 1032, 1031, 1030, 1029, 1028, 1027, 1026, 1025, 1070, 1071, 1072, 1073, 1074, 1075, 1076, 1077, 1078, 1079, 1080, 1081, 1082, 1083, 1084, 1085, 1086, 1087, 1088, 1089, 1090, 1091, 1092, 1093, 1094, 1095, 1096, 1097, 1098, 1099, 1100, 1101, 1102, 1103, 1104, 1105, 1106, 1107, 1108, 1109, 1110, 1111, 1112, 1113, 1157, 1156, 1155, 1154, 1153, 1152, 1151, 1150, 1149, 1148, 1147, 1146, 1145, 1144, 1143, 1142, 1141, 1140, 1139, 1138, 1137, 1136, 1135, 1134, 1133, 1132, 1131, 1130, 1129, 1128, 1127, 1126, 1125, 1124, 1123, 1122, 1121, 1120, 1119, 1118, 1117, 1116, 1115, 1114, 1159, 1160, 1161, 1162, 1163, 1164, 1165, 1166, 1167, 1168, 1169, 1170, 1171, 1172, 1173, 1174, 1175, 1176, 1177, 1178, 1179, 1180, 1181, 1182, 1183, 1184, 1185, 1186, 1187, 1188, 1189, 1190, 1191, 1192, 1193, 1194, 1195, 1196, 1197, 1198, 1199, 1200, 1201, 1202, 1246, 1245, 1244, 1243, 1242, 1241, 1240, 1239, 1238, 1237, 1236, 1235, 1234, 1233, 1232, 1231, 1230, 1229, 1228, 1227, 1226, 1225, 1224, 1223, 1222, 1221, 1220, 1219, 1218, 1217, 1216, 1215, 1214, 1213, 1212, 1211, 1210, 1209, 1208, 1207, 1206, 1205, 1204, 1203, 1248, 1249, 1250, 1251, 1252, 1253, 1254, 1255, 1256, 1257, 1258, 1259, 1260, 1261, 1262, 1263, 1264, 1265, 1266, 1267, 1268, 1269, 1270, 1271, 1272, 1273, 1274, 1275, 1276, 1277, 1278, 1279, 1280, 1281, 1282, 1283, 1284, 1285, 1286, 1287, 1288, 1289, 1290, 1291, 1335, 1334, 1333, 1332, 1331, 1330, 1329, 1328, 1327, 1326, 1325, 1324, 1323, 1322, 1321, 1320, 1319, 1318, 1317, 1316, 1315, 1314, 1313, 1312, 1311, 1310, 1309, 1308, 1307, 1306, 1305, 1304, 1303, 1302, 1301, 1300, 1299, 1298, 1297, 1296, 1295, 1294, 1293, 1292, 1337, 1338, 1339, 1340, 1341, 1342, 1343, 1344, 1345, 1346, 1347, 1348, 1349, 1350, 1351, 1352, 1353, 1354, 1355, 1356, 1357, 1358, 1359, 1360, 1361, 1362, 1363, 1364, 1365, 1366, 1367, 1368, 1369, 1370, 1371, 1372, 1373, 1374, 1375, 1376, 1377, 1378, 1379, 1380, 1424, 1423, 1422, 1421, 1420, 1419, 1418, 1417, 1416, 1415, 1414, 1413, 1412, 1411, 1410, 1409, 1408, 1407, 1406, 1405, 1404, 1403, 1402, 1401, 1400, 1399, 1398, 1397, 1396, 1395, 1394, 1393, 1392, 1391, 1390, 1389, 1388, 1387, 1386, 1385, 1384, 1383, 1382, 1381, 1426, 1427, 1428, 1429, 1430, 1431, 1432, 1433, 1434, 1435, 1436, 1437, 1438, 1439, 1440, 1441, 1442, 1443, 1444, 1445, 1446, 1447, 1448, 1449, 1450, 1451, 1452, 1453, 1454, 1455, 1456, 1457, 1458, 1459, 1460, 1461, 1462, 1463, 1464, 1465, 1466, 1467, 1468, 1469, 1513, 1512, 1511, 1510, 1509, 1508, 1507, 1506, 1505, 1504, 1503, 1502, 1501, 1500, 1499, 1498, 1497, 1496, 1495, 1494, 1493, 1492, 1491, 1490, 1489, 1488, 1487, 1486, 1485, 1484, 1483, 1482, 1481, 1480, 1479, 1478, 1477, 1476, 1475, 1474, 1473, 1472, 1471, 1470, 1515, 1516, 1517, 1518, 1519, 1520, 1521, 1522, 1523, 1524, 1525, 1526, 1527, 1528, 1529, 1530, 1531, 1532, 1533, 1534, 1535, 1536, 1537, 1538, 1539, 1540, 1541, 1542, 1543, 1544, 1545, 1546, 1547, 1548, 1549, 1550, 1551, 1552, 1553, 1554, 1555, 1556, 1557, 1558, 1602, 1601, 1600, 1599, 1598, 1597, 1596, 1595, 1594, 1593, 1592, 1591, 1590, 1589, 1588, 1587, 1586, 1585, 1584, 1583, 1582, 1581, 1580, 1579, 1578, 1577, 1576, 1575, 1574, 1573, 1572, 1571, 1570, 1569, 1568, 1567, 1566, 1565, 1564, 1563, 1562, 1561, 1560, 1559, 1604, 1605, 1606, 1607, 1608, 1609, 1610, 1611, 1612, 1613, 1614, 1615, 1616, 1617, 1618, 1619, 1620, 1621, 1622, 1623, 1624, 1625, 1626, 1627, 1628, 1629, 1630, 1631, 1632, 1633, 1634, 1635, 1636, 1637, 1638, 1639, 1640, 1641, 1642, 1643, 1644, 1645, 1646, 1647, 1691, 1690, 1689, 1688, 1687, 1686, 1685, 1684, 1683, 1682, 1681, 1680, 1679, 1678, 1677, 1676, 1675, 1674, 1673, 1672, 1671, 1670, 1669, 1668, 1667, 1666, 1665, 1664, 1663, 1662, 1661, 1660, 1659, 1658, 1657, 1656, 1655, 1654, 1653, 1652, 1651, 1650, 1649, 1648, 1693, 1694, 1695, 1696, 1697, 1698, 1699, 1700, 1701, 1702, 1703, 1704, 1705, 1706, 1707, 1708, 1709, 1710, 1711, 1712, 1713, 1714, 1715, 1716, 1717, 1718, 1719, 1720, 1721, 1722, 1723, 1724, 1725, 1726, 1727, 1728, 1729, 1730, 1731, 1732, 1733, 1734, 1735, 1736, 1780, 1779, 1778, 1777, 1776, 1775, 1774, 1773, 1772, 1771, 1770, 1769, 1768, 1767, 1766, 1765, 1764, 1763, 1762, 1761, 1760, 1759, 1758, 1757, 1756, 1755, 1754, 1753, 1752, 1751, 1750, 1749, 1748, 1747, 1746, 1745, 1744, 1743, 1742, 1741, 1740, 1739, 1738, 1737, 1782, 1783, 1784, 1785, 1786, 1787, 1788, 1789, 1790, 1791, 1792, 1793, 1794, 1795, 1796, 1797, 1798, 1799, 1800, 1801, 1802, 1803, 1804, 1805, 1806, 1807, 1808, 1809, 1810, 1811, 1812, 1813, 1814, 1815, 1816, 1817, 1818, 1819, 1820, 1821, 1822, 1823, 1824, 1825, 1869, 1868, 1867, 1866, 1865, 1864, 1863, 1862, 1861, 1860, 1859, 1858, 1857, 1856, 1855, 1854, 1853, 1852, 1851, 1850, 1849, 1848, 1847, 1846, 1845, 1844, 1843, 1842, 1841, 1840, 1839, 1838, 1837, 1836, 1835, 1834, 1833, 1832, 1831, 1830, 1829, 1828, 1827, 1826, 1871, 1872, 1873, 1874, 1875, 1876, 1877, 1878, 1879, 1880, 1881, 1882, 1883, 1884, 1885, 1886, 1887, 1888, 1889, 1890, 1891, 1892, 1893, 1894, 1895, 1896, 1897, 1898, 1899, 1900, 1901, 1902, 1903, 1904, 1905, 1906, 1907, 1908, 1909, 1910, 1911, 1912, 1913, 1914, 1958, 1957, 1956, 1955, 1954, 1953, 1952, 1951, 1950, 1949, 1948, 1947, 1946, 1945, 1944, 1943, 1942, 1941, 1940, 1939, 1938, 1937, 1936, 1935, 1934, 1933, 1932, 1931, 1930, 1929, 1928, 1927, 1926, 1925, 1924, 1923, 1922, 1921, 1920, 1919, 1918, 1917, 1916, 1915, 1, 90, 179, 268, 357, 446, 535, 624, 713, 802, 891, 980, 1069, 1158, 1247, 1336, 1425, 1514, 1603, 1692, 1781, 1870, 1959]

  @test size( calibSNR(sm) ) == (817,3,1)
  @test calibFov(sm) == [0.044; 0.044; 0.001]
  @test calibFovCenter(sm) == [0.0; -0.0; 0.0]
  @test calibSize(sm) == [44; 44; 1]
  @test calibOrder(sm) == "xyz"
  @test calibDeltaSampleSize(sm) == [0.0, 0.0, 0.0] #[0.001; 0.001; 0.001]
  @test calibMethod(sm) == "robot"

  @test size(filterFrequencies(sm, SNRThresh = 5)) == (147,)
  #@test size(filterFrequencies(sm, numUsedFreqs = 100)) == (100,) # not working

  @test size(getSystemMatrix(sm,1:10)) == (1936,10)
  @test size(getSystemMatrix(sm,1:10,loadasreal=true)) == (1936,20)
  @test size(getSystemMatrix(sm,1:10,bgCorrection=true)) == (1936,10)
  # test on the data level if the conversion was successfull
  SNRThresh = 2
  freq = filterFrequencies(smBruker,SNRThresh=SNRThresh)
  SBruker = getSystemMatrix(smBruker,frequencies=freq)
  S = getSystemMatrix(sm,frequencies=freq)
  relativeDeviation = zeros(Float32,length(freq))
  for f in 1:length(freq)
    relativeDeviation[f] = norm(SBruker[:,f]-S[:,f])/norm(SBruker[:,f])
  end
  # test if relative deviation for most of the frequency components is below 0.003
  @test quantile(relativeDeviation,0.95)<0.003
end

# Next test checks if the cached system matrix is the same as the one loaded
# from the raw data
S_loadedfromraw = getMeasurementsFD(smBrukerPretendToBeMeas,
      frames=1:acqNumFGFrames(smBrukerPretendToBeMeas),sortFrames=true,
      spectralLeakageCorrection=false,transposed=true)

S_loadedfromproc = systemMatrix(smBruker)

@test norm(vec(S_loadedfromraw-S_loadedfromproc)) / norm(vec(S_loadedfromproc)) < 1e-6


# Calibration file 1D

# Calibration File

sm1DBruker = MPIFile(fnSM1DBruker)
@test typeof(sm1DBruker) == BrukerFileCalib

saveasMDF(fnSM1DV1, sm1DBruker)

sm1D = MPIFile(fnSM1DV1)
@test typeof(sm1D) == MDFFileV2


for sm in (sm1DBruker,sm1D)
  @info "Test $sm"

  @test size( systemMatrixWithBG(sm) ) == (67,52,3,1)
  @test size( systemMatrix(sm,1:10) ) == (60,10)
  @test size( systemMatrix(sm) ) == (60,52,3,1)

  @test size(calibSNR(sm)) == (52, 3, 1)

  @test rxNumSamplingPoints(sm) == 102
  @test rxNumFrequencies(sm) == 52
end


sm1DBrukerMeas = MPIFile(fnSM1DBruker, isCalib=false)
saveasMDF(fnSM1DV2, sm1DBrukerMeas)

sm1DMeas = MPIFile(fnSM1DV2)
@test typeof(sm1DMeas) == MDFFileV2

for sm in (sm1DBrukerMeas,sm1DMeas)
  @info "Test $sm"

  @test size(measData(sm)) == (102, 3, 1, 67)

  @test rxNumSamplingPoints(sm) == 102
  @test rxNumFrequencies(sm) == 52
end




end
