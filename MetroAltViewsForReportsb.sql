/*
A summary of how many buses are assigned to each bus barn
A schedule for a particular bus (do this as a stored procedure where the buskey can be passed as a parameter. This will simply be a schedule of the stops not the times since somehow that table didn't get populated.)
The total revenues per city per year
The total cost of buses by Bus type
The total revenues per year
The count of employees by position
The total amount earned by a driver in a year (make it a stored procedure and pass in year and driverKey as parameters)
The cost of a bus versus the amount of fares earned by that bus across the three years. (Does the bus pay for itself) pass in the buskey as a parameter.

*/

--busses per bus barn
use MetroAlt

go
Create view vw_BussesPerBarn
As
Select BusBarnAddress, BusBarnCity, count(BusKey) [Bus Count]
From BusBarn bb
inner join bus b
on b.BusBarnKey=bb.BusBarnKey
Group by BusbarnAddress, busBarnCity

Go
--Bus schedule procedure
Create proc usp_BusSchedule
@Buskey int
As
Select Distinct bsa.Buskey, br.BusRouteKey, BusStopAddress, BusStopCity
From BusScheduleAssignment bsa
inner join Busroute br
on bsa.BusRouteKey=br.BusRouteKey
inner join BusRouteStops brs
on br.BusRouteKey=brs.BusRouteKey
inner join BusStop bs
on brs.BusStopKey=bs.BusStopKey
Where bsa.busKey=@BusKey

Go
--Earnings by City

Create view vw_EarningsByCity
As
Select Year(BusScheduleAssignmentDate) [Year], 
BusRouteZone City, format(sum(riders*fareamount),'$#,##0.00') TotalEarnings
From BusScheduleAssignment bsa
inner join BusRoute br
on bsa.BusRouteKey=br.BusRouteKey
inner join Ridership r
on bsa.BusScheduleAssignmentKey=r.BusScheduleAssigmentKey
inner join Fare f
on f.FareKey=r.FareKey
Group by Year(BusScheduleAssignmentDate), BusRouteZone

--this is just to see total amount
Select format(sum(FareAmount * riders),'$#,##0.00')
From Fare f
inner join Ridership r
on f.FareKey=r.FareKey

Go
--Cost by bus type
Create View vw_CostByBusType
As
Select BusTypeDescription, Count(Buskey) as Count, Sum(BusTypePurchasePrice) [Total Spent]
From Bustype bt
inner join Bus b
on bt.BusTypeKey=b.BusTypeKey
Group by BusTypeDescription

Go
--Total earnings per year
Create view vw_EarningsByYear
As
Select year(BusScheduleAssignmentDate) [Year], format(Sum(fareAmount * riders), '$#,##0.00') Total
From BusScheduleAssignment bsa
inner join ridership r
on r.BusScheduleAssigmentKey=bsa.BusScheduleAssignmentKey
inner join Fare f
on f.FareKey=r.FareKey
Group by  year(BusScheduleAssignmentDate)

Go
--employees by position
Create view vw_EmployeesByPosition
As
Select PositionName, Count(EmployeeKey) [Count]
From Position p
inner join EmployeePosition ep
on p.PositionKey=ep.PositionKey
Group by PositionName

Go
--One employees annual wage--stored proc taking year and employeeKey
--
Alter proc usp_EmployeeWage
@EmployeeKey int,
@Year int
As
Select e.employeeKey, YEAR(BusScheduleAssignmentDate) [Year],
EmployeeLastName, EmployeeHourlyPayRate, sum(dateDiff(hh,BusDriverShiftStartTime, BusDriverShiftStopTime)) [Hours],
Sum(EmployeeHourlyPayRate * dateDiff(hh,BusDriverShiftStartTime, BusDriverShiftStopTime)) PAY
From BusScheduleAssignment bsa
inner Join BusDriverShift bds
on bsa.BusDriverShiftKey=bds.BusDriverShiftKey
inner join Employee e
on e.EmployeeKey=bsa.EmployeeKey
inner join EmployeePosition ep
on e.EmployeeKey=ep.EmployeeKey
Where YEAR(BusScheduleAssignmentDate)=@Year 
and e.Employeekey=@EmployeeKey
Group by YEAR(BusScheduleAssignmentDate),
e.EmployeeKey,EmployeeLastName, EmployeeHourlyPayRate

Go
--Cost of bus vs fares earned
Create proc Usp_BusPriceVsEarnings
@Buskey int
As
Select b.BusKey, BusTypePurchasePrice, sum (fareAmount * riders) [Total Fares],
sum (fareAmount * riders) - BusTypePurchasePrice[Difference]
From Bus b
inner join Bustype bt
on b.BusTypekey =bt.BusTypeKey
inner join BusScheduleAssignment bsa
on b.BusKey=bsa.BusKey
inner join ridership r
on r.BusScheduleAssigmentKey=bsa.BusScheduleAssignmentKey
inner join fare f
on f.FareKey=r.FareKey
Where b.BusKey=@BusKey
Group by b.BusKey, BustypePurchasePrice




