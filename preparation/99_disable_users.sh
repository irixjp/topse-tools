USERLIST='0501
0502
0503
0504
0505
0506
0507
0508
0509
0510
0511
0512
0513
0514
0515
0516
0517
0518
0519
0520
0521
0522
0523
0524
0525
0526
0527
0528
0529
0530
0531
0532
0533
0534
0535
0536
0537
0538
0539
0540
0541
0542
0543
0544
0545
0546
0547
0548
0549
0550'

for USER_NUM in ${USERLIST}
do
  echo "### ${USER_NUM}"
  openstack user set student-${USER_NUM} --disable
done
