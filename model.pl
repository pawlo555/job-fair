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
    Obj in 1..1000,
	generateListOfVariables(Companies, TimeSlots, ListOfVariables),
    calcAGHCost(TimeSlots, AGHCost),
    calcCompaniesCost(Companies, TimeSlots, AttendanceCosts, CompaniesCost),
    calcStudentExpectation(Companies, Preferences, Expectation, StudentsCost),
    StudentsCost #= 10,
    calcObj(AGHCost, CompaniesCost, StudentsCost, Obj),
    labeling([ff], [Obj|ListOfVariables]).

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
    calcCompaniesCost(Companies, TimeSlots, AttendanceCosts, CompaniesCost, 1).


calcCompaniesCost(_Companies, _TimeSlots, _AttendanceCosts, 10, 1).

calcStudentExpectation(Companies, Preferences, StudentsExpectations, StudentsCost) :-
    studentsMatch(Companies, Preferences, Match),
    calcExpectation(Match, StudentsExpectations, StudentsCost).

studentsMatch([], [], []).
studentsMatch([Comp1, Comp2, Comp3|Companies], [StudentPreferences|Preferences], Match) :-
    StudentMatch in 3..15,
    [Like1, Like2, Like3] ins 1..5,
    like(Comp1, StudentPreferences, Like1),
    like(Comp2, StudentPreferences, Like2),
    like(Comp3, StudentPreferences, Like3),
    sum([Like1, Like2, Like3], #=, StudentMatch),
    Match = [StudentMatch|Match1],
    studentsMatch(Companies, Preferences, Match1).

like(_, [], _).
like(Company, [Pref|StudentPreferences], Like) :-
    Company1 #= Company-1,
    Company #= 1 #<==> Like #= Pref,
    like(Company1, StudentPreferences, Like).
    
    

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