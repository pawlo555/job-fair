:- use_module(library(clpfd)).

sizeOf2DList([], 0, _ ).
sizeOf2DList([X|List], Length, ElementsInLine) :-
    Length #> 0,
    length(X, ElementsInLine),
    Length1 #= Length-1,
    sizeOf2DList(List, Length1, ElementsInLine).

studentsInTimeSlots([], []).
studentsInTimeSlots([Slot1, Slot2, Slot3|TimeSlots], [AvailableSlots|Slots]) :-
    createDomain(AvailableSlots, Domain),
    Slot1 in Domain,
    Slot2 in Domain,
    Slot3 in Domain,
   	studentsInTimeSlots(TimeSlots, Slots).

createDomain([X], X).
createDomain([X|List], Domain) :-
    Domain =  X \/ RestDomain,
    createDomain(List, RestDomain).

differentTimeSlots([]).
differentTimeSlots([Slot1, Slot2, Slot3|TimeSlots]) :-
    chain([Slot1,Slot2,Slot3], #>),
    differentTimeSlots(TimeSlots).

differentCompanies([]).
differentCompanies([Company1, Company2, Company3 | Companies]) :-
    all_different([Company1, Company2, Company3]),
    differentCompanies(Companies).

jobFair(Nstudents, Ncompanies, Slots, Preferences, Parallel_limits, Expectation, MinCap, MaxCap, AttendanceCosts, Companies, TimeSlots, Obj) :-
    length(Slots, Nstudents),
    sizeOf2DList(Preferences, Nstudents, Ncompanies),
    length(Parallel_limits, Ncompanies),
    length(Expectation, Nstudents),
    length(MinCap, Ncompanies),
    length(MaxCap, Ncompanies),
    length(AttendanceCosts, Ncompanies),
    Meetings #= 3*Nstudents,
    length(Companies, Meetings),
    Companies ins 1..Ncompanies,
    length(TimeSlots, Meetings),
	TimeSlots ins 1..20,
    differentTimeSlots(TimeSlots),
    studentsInTimeSlots(TimeSlots, Slots),
    differentCompanies(Companies),
    companiesLimits(Companies, Ncompanies, MinCap, MaxCap),
    parallel_limits(Companies, TimeSlots, Ncompanies,  Parallel_limits),
    generateListOfVariables(Companies, TimeSlots, ListOfVariables),
    Obj in 1..10000,
    %labeling([ff, bisect], ListOfVariables),
    calcAGHCost(TimeSlots, AGHCost),
    calcStudentExpectation(Companies, Preferences, Expectation, StudentsCost),
    calcCompaniesCost(Companies, TimeSlots, AttendanceCosts, CompaniesCost),
    calcObj(AGHCost, CompaniesCost, StudentsCost, Obj),
    labeling([ff, bisect, min(Obj)], [Obj|ListOfVariables]),
    writeln(AGHCost-CompaniesCost-StudentsCost).

studentsPerCompany([], _, 0).
studentsPerCompany([CompanyNumber1|Companies], CompanyNumber, StudentsNumber) :-
    IsInteriewWithCompany in 0..1,
    CompanyNumber #= CompanyNumber1 #<==> IsInteriewWithCompany,
    StudentsNumber #= IsInteriewWithCompany + StudentsNumber1,
    studentsPerCompany(Companies, CompanyNumber, StudentsNumber1).
studentsPerCompany([OtherCompany|Companies], CompanyNumber, StudentsNumber) :-
    OtherCompany #\= CompanyNumber,
    studentsPerCompany(Companies, CompanyNumber, StudentsNumber).

companiesLimits(Companies, Ncompanies, MinCap, MaxCap) :-
    companiesLimits(Companies, Ncompanies, MinCap, MaxCap, Ncompanies).

companiesLimits(_, _, [], [], _).
companiesLimits(Companies, Ncompanies, [Min|MinCap], [Max|MaxCap], CurrentCompany) :-
    studentsPerCompany(Companies, CurrentCompany, StudentsNumber),
    Min #=< StudentsNumber,
    Max #>= StudentsNumber,
    CurrentCompany #= CurrentCompany1+1,
    companiesLimits(Companies, Ncompanies, MinCap, MaxCap, CurrentCompany1).

generateListOfVariables(Companies, TimeSlots, ListOfVariables) :-
    append(Companies, TimeSlots, ListOfVariables).

parallel_limits(Companies, TimeSlots, Ncompanies, CompaniesLimits) :-
	parallel_limits(Companies, TimeSlots, Ncompanies, CompaniesLimits, 1).

parallel_limits(_, _,_, _, 21).
parallel_limits(Companies, TimeSlots, Ncompanies, CompaniesLimits, TimeSlot) :-
    parallel_limits(Companies, TimeSlots, Ncompanies, CompaniesLimits, TimeSlot, 1),
    TimeSlot1 #= TimeSlot+1,
    parallel_limits(Companies, TimeSlots, Ncompanies, CompaniesLimits, TimeSlot1).

parallel_limits(_, _, Ncompanies, _, _, Ncompanies).
parallel_limits(Companies, TimeSlots, Ncompanies, [CompLimit|CompaniesLimits], TimeSlot, CurrentCompany) :-
    companyInterviewsInTimeSlot(Companies, TimeSlots, TimeSlot, CurrentCompany, InterviewsInTime),
    CompLimit #>= InterviewsInTime,
    NextCompany #= CurrentCompany+1,
    parallel_limits(Companies, TimeSlots, Ncompanies, CompaniesLimits, TimeSlot, NextCompany).

companyInterviewsInTimeSlot([], [], _, _, 0).
companyInterviewsInTimeSlot([Company1|Companies], [TimeSlot1|TimeSlots],
                            TimeSlot, Company, Interviews) :-
    IsInterview in 0..1,
    (Company1 #= Company #/\ TimeSlot1 #= TimeSlot) #<==> IsInterview,
    Interviews #= Interviews1+IsInterview,
    companyInterviewsInTimeSlot(Companies, TimeSlots, TimeSlot, Company, Interviews1).


% stage 2 calculating objective

calcObj(AGHCost, CompaniesCost, StudentsExpectations, Obj) :-
    Obj #= AGHCost + CompaniesCost + StudentsExpectations.

calcAGHCost(TimeSlots, AGHCost) :-
    maxRoomsInTimeSlot(TimeSlots, MaxRooms),
	AGHCost #= 200*MaxRooms.

maxRoomsInTimeSlot(TimeSlots, MaxRooms) :-
    maxRoomsInTimeSlot(TimeSlots, MaxList, 1),
    listMax(MaxList, MaxRooms).

maxRoomsInTimeSlot(_, [], 21).
maxRoomsInTimeSlot(TimeSlots, MaxList, TimeSlot) :-
    roomsInTimeSlot(TimeSlots, TimeSlot, RoomsNumber),
    MaxList = [RoomsNumber|RestMaxList],
    TimeSlot1 #= TimeSlot+1,
    maxRoomsInTimeSlot(TimeSlots, RestMaxList, TimeSlot1).

roomsInTimeSlot([], _, 0).
roomsInTimeSlot([Slot|TimeSlots], TimeSlot, RoomsNumber) :-
    IsSlot in 0..1,
    Slot #= TimeSlot #<==> IsSlot,
    RoomsNumber #= RoomsNumber1+IsSlot,
    roomsInTimeSlot(TimeSlots, TimeSlot, RoomsNumber1).

listMax([], 0).
listMax([X|Rest], Max) :-
    listMax(Rest, RestMax),
   	Max #= max(X, RestMax).

calcCompaniesCost(Companies, TimeSlots, AttendanceCosts, CompaniesCost) :-
    calcAllSlotsInAGH(Companies, TimeSlots, FirstSlots, LastSlots, AttendanceCosts, 1),
    calcCompaniesCostDays(FirstSlots, LastSlots, AttendanceCosts, CompaniesCost).

calcAllSlotsInAGH(_, _, [], [], [], _).
calcAllSlotsInAGH(Companies, TimeSlots, FirstSlots, LastSlots, [_|CompaniesCost], Ncompany) :-
    [FirstSlot, LastSlot] ins 1..20,
    FirstSlot #=< LastSlot,
    calcSlotInAGH(Companies, TimeSlots, FirstSlot, LastSlot, Ncompany),
    labeling([max(FirstSlot), min(LastSlot)],[FirstSlot, LastSlot]),
    FirstSlots = [FirstSlot|FirstSlots1],
    LastSlots = [LastSlot|LastSlots1],
    Ncompany1 #= Ncompany + 1,
    calcAllSlotsInAGH(Companies, TimeSlots, FirstSlots1, LastSlots1, CompaniesCost, Ncompany1).

calcSlotInAGH([], [], _, _, _).

calcSlotInAGH([Company|Companies], [Slot|TimeSlots], FirstSlot, LastSlot, Ncompany) :-
    Company #= Ncompany #==> (FirstSlot #=< Slot) #/\ (LastSlot #>= Slot),
    calcSlotInAGH(Companies, TimeSlots, FirstSlot, LastSlot, Ncompany).

calcCompaniesCostDays([],[],[],0).
calcCompaniesCostDays([FirstSlot|FirstSlots], [LastSlot|LastSlots], [Cost|AttendanceCosts], CompaniesCost) :-
    getDayFromTimeSlot(FirstSlot, ArrivalDay),
    getDayFromTimeSlot(LastSlot, DepartureDay),
    CompaniesCost #= (DepartureDay-ArrivalDay + 1) * Cost + CompaniesCost1,
    calcCompaniesCostDays(FirstSlots, LastSlots, AttendanceCosts, CompaniesCost1).

getDayFromTimeSlot(TimeSlot, Day) :-
    TimeSlot in 1..20,
    Day in 1..5,
    Day #= (TimeSlot-1) // 4 + 1.

calcStudentExpectation(Companies, Preferences, StudentsExpectations, StudentsCost) :-
    studentsMatch(Companies, Preferences, Match),
    calcExpectation(Match, StudentsExpectations, StudentsCost).

studentsMatch([], [], []).
studentsMatch([Comp1, Comp2, Comp3|Companies], [StudentPreferences|Preferences], Match) :-
    StudentMatch in 3..15,
    [Like1, Like2, Like3] ins 1..5,
   	element(Comp1, StudentPreferences, Like1),
    element(Comp2, StudentPreferences, Like2),
    element(Comp3, StudentPreferences, Like3),
    sum([Like1, Like2, Like3], #=, StudentMatch),
    Match = [StudentMatch|Match1],
    studentsMatch(Companies, Preferences, Match1).    

calcExpectation([], [], 0).
calcExpectation([StudentMatch|Match], [StudentsExpectation|Expecations], Result) :-
    Cost in 0..12,
    Diff #= StudentMatch-StudentsExpectation,
    Cost #= max(Diff, 0),
    Result #= Result1+Cost,
    calcExpectation(Match, Expecations, Result1).

/*
jobFair(4, 4, 
 [[15, 16, 17, 18, 19, 20],
 [1, 2, 3, 4, 5, 6],
 [1, 2, 7, 8, 9, 10, 11],
 [7, 8, 9, 10, 11]], 
 [[3, 4, 1, 1],
 [2, 4, 4, 1],
 [3, 4, 3, 5],
 [5, 2, 3, 1]],
 [2, 1, 2, 1], [5, 3, 4, 3], [1,1,1,1], [10, 6, 3, 7], [20, 20, 10, 30],  
 Companies, TimeSlots, Obj).
*/