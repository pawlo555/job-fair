:- use_module(library(clpfd)).

sizeOf2DList([], 0, _ ).
sizeOf2DList([X|List], Length, ElementsInLine) :-
    Length #> 0,
    length(X, ElementsInLine),
    Length1 #= Length-1,
    sizeOf2DList(List, Length1, ElementsInLine).

studentsInTimeSlots([], []).
studentsInTimeSlots([Slot1, Slot2, Slot3|TimeSlots], [AvailableSlots|Slots]) :-
    member(Slot1, AvailableSlots),
    member(Slot2, AvailableSlots),
    member(Slot3, AvailableSlots),
   	studentsInTimeSlots(TimeSlots, Slots).

differentTimeSlots([]).
differentTimeSlots([Slot1, Slot2, Slot3|TimeSlots]) :-
    all_different([Slot1, Slot2, Slot3]),
    Slot1 #< Slot2,
    Slot2 #< Slot3,
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
    calcObj(Companies, TimeSlots, AttendanceCosts, Preferences, Obj),
    labeling([min(Obj), ff], [Obj|ListOfVariables]).


studentsPerCompany([], _, 0).
studentsPerCompany([CompanyNumber|Companies], CompanyNumber, StudentsNumber) :-
    StudentsNumber #= StudentsNumber1+1,
    studentsPerCompany(Companies, CompanyNumber, StudentsNumber1).
studentsPerCompany([OtherCompany|Companies], CompanyNumber, StudentsNumber) :-
    OtherCompany #\= CompanyNumber,
    studentsPerCompany(Companies, CompanyNumber, StudentsNumber).

companiesLimits(Companies, Ncompanies, MinCap, MaxCap) :-
    companiesLimits(Companies, Ncompanies, MinCap, MaxCap, Ncompanies).

companiesLimits(_, _, [], [], 0).
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

parallel_limits(_, _,_, [], 21).
parallel_limits(Companies, TimeSlots, Ncompanies, CompaniesLimits, TimeSlot) :-
    parallel_limits(Companies, TimeSlots, Ncompanies, CompaniesLimits, TimeSlot, 1),
    TimeSlot1 #= TimeSlot+1,
    parallel_limits(Companies, TimeSlots, CompaniesLimits, TimeSlot1).

parallel_limits(_, _, Ncompanies, _, _, Ncompanies).
parallel_limits(Companies, TimeSlots, Ncompanies, [CompLimit|CompaniesLimits], TimeSlot, CurrentCompany) :-
    companyInterviewsInTimeSlot(Companies, TimeSlots, TimeSlot, CurrentCompany, InterviewsInTime),
    CompLimit #>= InterviewsInTime,
    NextCompany #= CurrentCompany+1,
    parallel_limits(Companies, TimeSlots, Ncompanies, CompaniesLimits, TimeSlot, NextCompany).

companyInterviewsInTimeSlot([], [], _, _, 0).
companyInterviewsInTimeSlot([Company|Companies], [TimeSlot|TimeSlots],
                            TimeSlot, Company, Interviews) :-
    Interviews #= Interviews1+1,
    companyInterviewsInTimeSlot(Companies, TimeSlots, TimeSlot, Company, Interviews1),
    write(Interviews).
companyInterviewsInTimeSlot([Company1|Companies], [_|TimeSlots],
                            TimeSlot, Company, Interviews) :-
    Company1 #\= Company,
    companyInterviewsInTimeSlot(Companies, TimeSlots, TimeSlot, Company, Interviews). 
companyInterviewsInTimeSlot([_|Companies], [TimeSlot1|TimeSlots],
                           TimeSlot, Company, Interviews) :-
   TimeSlot1 #\= TimeSlot,
   companyInterviewsInTimeSlot(Companies, TimeSlots, TimeSlot, Company, Interviews). 


calcObj(Companies, TimeSlots, AttendaceCosts, Preferences, Obj) :-
    calcAGHCost(TimeSlots, AGHCost),
    calcCompaniesCost(Companies, TimeSlots, AttendaceCosts, CompaniesCost),
    calcStudentExpectation(TimeSlots, Preferences, StudentsExpectations),
    Obj #= AGHCost + CompaniesCost + StudentsExpectations.

calcAGHCost(_TimeSlots, AGHCost) :-
	AGHCost #= 200.

calcCompaniesCost(_Companies, _TimeSlots, _AttendanceCosts, CompaniesCost) :-
    CompaniesCost #= 10.

calcStudentExpectation(_TimeSlots, _Preferences, StudentsExpectations) :-
    StudentsExpectations #= 100.

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