-- удаляем таблицы для повторного запуска
DROP TABLE IF EXISTS Ticket, ScreeningSeat, FilmGenre, Screening, Seat, Hall, Genre, Film, Client;

CREATE TABLE Film (
    film_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    duration INT NOT NULL CHECK (duration > 0), -- длительность не может быть отрицательной
    release_date DATE NOT NULL
);

CREATE TABLE Genre (
    genre_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE -- жанры не должны повторяться
);

CREATE TABLE Hall (
    hall_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0) -- вместимость > 0
);

CREATE TABLE Client (
    client_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE Seat (
    seat_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    hall_id INT NOT NULL,
    seat_number INT NOT NULL,
    FOREIGN KEY (hall_id) REFERENCES Hall(hall_id),
    UNIQUE (hall_id, seat_number) -- уникальный номер места в зале
);

CREATE TABLE Screening (
    screening_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    film_id INT NOT NULL,
    hall_id INT NOT NULL,
    screening_date DATE NOT NULL CHECK (screening_date > '2026-01-01'), -- дата после 2026
    screening_time TIME NOT NULL,
    FOREIGN KEY (film_id) REFERENCES Film(film_id),
    FOREIGN KEY (hall_id) REFERENCES Hall(hall_id)
);

CREATE TABLE FilmGenre (
    film_id INT NOT NULL,
    genre_id INT NOT NULL,
    PRIMARY KEY (film_id, genre_id), -- связь many-to-many
    FOREIGN KEY (film_id) REFERENCES Film(film_id),
    FOREIGN KEY (genre_id) REFERENCES Genre(genre_id)
);

CREATE TABLE ScreeningSeat (
    screening_seat_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    screening_id INT NOT NULL,
    seat_id INT NOT NULL,
    FOREIGN KEY (screening_id) REFERENCES Screening(screening_id),
    FOREIGN KEY (seat_id) REFERENCES Seat(seat_id),
    UNIQUE (screening_id, seat_id) -- нельзя продать одно место дважды
);

CREATE TABLE Ticket (
    ticket_id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    screening_seat_id INT NOT NULL,
    client_id INT NOT NULL,
    price DECIMAL(8,2) NOT NULL DEFAULT 0 CHECK (price >= 0), -- цена не отрицательная
    FOREIGN KEY (screening_seat_id) REFERENCES ScreeningSeat(screening_seat_id),
    FOREIGN KEY (client_id) REFERENCES Client(client_id)
);