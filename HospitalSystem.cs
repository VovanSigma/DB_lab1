using System;

// Базовий клас, який виконує виклики процедур та запити до представлень.
public class DatabaseContext
{
    public void CallProcedure(string name, params object[] args)
    {
        Console.WriteLine($"CALL {name}({string.Join(", ", args)})");
    }

    public void SelectView(string viewName)
    {
        Console.WriteLine($"SELECT * FROM {viewName}");
    }

    public void BeginTransaction()
    {
        Console.WriteLine("BEGIN");
    }

    public void Commit()
    {
        Console.WriteLine("COMMIT");
    }

    public void Close()
    {
        Console.WriteLine("END");
    }
}

// Інтерфейс репозиторію для роботи з сутністю
public interface IRepository<T>
{
    void Add(T entity);
    T Get(int id);
}

// Сутність "Пацієнт"
public class Patient
{
    public int Id { get; set; }
    public string FullName { get; set; }
}

// Сутність "Прийом"
public class Appointment
{
    public int Id { get; set; }
    public string Description { get; set; }
}

// Репозиторій пацієнтів
public class PatientRepository : IRepository<Patient>
{
    private readonly DatabaseContext _db;

    public PatientRepository(DatabaseContext db)
    {
        _db = db;
    }

    public void Add(Patient p)
    {
        _db.CallProcedure(
            "create_patient",
            p.FullName,
            "NULL",
            "NULL",
            "NULL",
            "NULL",
            "NULL",
            "NULL",
            "{}",
            "system"
        );

        Console.WriteLine($"Додано пацієнта: {p.FullName}");
    }

    public Patient Get(int id)
    {
        _db.SelectView("vw_active_patients");
        return new Patient { Id = id, FullName = "Пацієнт" };
    }
}

// Репозиторій прийомів
public class AppointmentRepository : IRepository<Appointment>
{
    private readonly DatabaseContext _db;

    public AppointmentRepository(DatabaseContext db)
    {
        _db = db;
    }

    public void Add(Appointment a)
    {
        _db.CallProcedure(
            "schedule_appointment",
            1,
            1,
            "NOW()",
            a.Description,
            "system"
        );

        Console.WriteLine($"Створено прийом: {a.Description}");
    }

    public Appointment Get(int id)
    {
        _db.SelectView("vw_appointments_detailed");
        return new Appointment { Id = id, Description = "Прийом" };
    }
}

// Unit of Work
public class UnitOfWork : IDisposable
{
    private readonly DatabaseContext _db;

    public PatientRepository Patients { get; }
    public AppointmentRepository Appointments { get; }

    public UnitOfWork()
    {
        _db = new DatabaseContext();
        Patients = new PatientRepository(_db);
        Appointments = new AppointmentRepository(_db);
    }

    public void Begin()
    {
        _db.BeginTransaction();
    }

    public void Commit()
    {
        _db.Commit();
    }

    public void Dispose()
    {
        _db.Close();
    }
}

// Основна програма
public class Program
{
    public static void Main()
    {
        using (var uow = new UnitOfWork())
        {
            uow.Begin();

            var patient = new Patient { FullName = "Петро Петренко" };
            uow.Patients.Add(patient);

            var appt = new Appointment { Description = "Первинна консультація" };
            uow.Appointments.Add(appt);

            var p = uow.Patients.Get(1);
            Console.WriteLine($"Отримано: {p.FullName}");

            var a = uow.Appointments.Get(1);
            Console.WriteLine($"Отримано: {a.Description}");

            uow.Commit();
        }
    }
}
