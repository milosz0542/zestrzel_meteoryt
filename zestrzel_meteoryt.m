function zestrzel_meteoryt()
    %{
    funkcja zestrzel_meteoryt()
    Służy ona do symulacji przechwytu meteorytu, który uderza w naszą sferę
    chronioną.
    %}

    clc; close all;

    % Grawitacja (m/s^2):
    g = 9.81;

    % Promień chronionej przestrzeni powietrznej (w metrach):
    R = 200000;  % 200 km

    % Generowanie losowych danych meteorytu
    disp('=== DANE METEORYTU ===');

    % Losowe współrzędne początkowe (w km)
    x0 = (rand() * 400 - 200) * 1000;  % -200km do +200km
    y0 = (rand() * 400 - 200) * 1000;
    z0 = (rand() * 20 + 5) * 1000;     % 5km do 25km

    % Losowa prędkość (30-100 m/s)
    v_m = 30 + rand() * 70;

    % Losowe kąty (0-360 stopni)
    alpha_m = rand() * 360;
    beta_m = rand() * 360;
    gamma_m = rand() * 360;

    % Wyświetlanie wygenerowanych danych
    fprintf('Początkowa pozycja meteorytu:\n');
    fprintf('x0 = %.2f km\n', x0/1000);
    fprintf('y0 = %.2f km\n', y0/1000);
    fprintf('z0 = %.2f km\n', z0/1000);
    fprintf('Prędkość meteorytu: %.2f m/s\n', v_m);
    fprintf('Kąty meteorytu:\n');
    fprintf('alpha = %.2f°\n', alpha_m);
    fprintf('beta = %.2f°\n', beta_m);
    fprintf('gamma = %.2f°\n', gamma_m);

    % Przeliczenie kątów na radiany i wyznaczenie składowych prędkości:
    alpha_m_rad = deg2rad(alpha_m);
    beta_m_rad  = deg2rad(beta_m);
    gamma_m_rad = deg2rad(gamma_m);

    vx_m = v_m * cos(alpha_m_rad);
    vy_m = v_m * cos(beta_m_rad);
    vz_m = v_m * cos(gamma_m_rad);

    % ========================
    % 1) Tor ruchu meteorytu z uwzględnieniem oporu powietrza (ode45)
    % ========================

    % Parametry oporu powietrza
    m = 1000;       % masa meteorytu [kg]
    k = 0.1;        % współczynnik oporu [kg/m]

    % Konwersja kątów na składowe prędkości
    vx_m = v_m * cosd(alpha_m) * cosd(beta_m);
    vy_m = v_m * sind(alpha_m) * cosd(beta_m);
    vz_m = v_m * sind(beta_m);

    % Funkcja do rozwiązania układu równań różniczkowych
    ode_fun = @(t, Y) [
        Y(4);  % dx/dt = vx
        Y(5);  % dy/dt = vy
        Y(6);  % dz/dt = vz
        -(k/m) * Y(4) * sqrt(Y(4)^2 + Y(5)^2 + Y(6)^2);  % dvx/dt
        -(k/m) * Y(5) * sqrt(Y(4)^2 + Y(5)^2 + Y(6)^2);  % dvy/dt
        -g - (k/m) * Y(6) * sqrt(Y(4)^2 + Y(5)^2 + Y(6)^2)  % dvz/dt
    ];

    % Warunki początkowe [x0, y0, z0, vx0, vy0, vz0]
    Y0 = [x0; y0; z0; vx_m; vy_m; vz_m];

    % Zdarzenie: zatrzymanie gdy z=0
    options = odeset('Events', @(t, Y) ground_event(t, Y));

    % Rozwiązanie numeryczne (ode45)
    [t, Y, ~, ~, ie] = ode45(ode_fun, [0 1000], Y0, options);

    % Sprawdzenie, czy meteoryt uderzył w ziemię
    if isempty(ie)
        disp('Meteoryt nie uderzy w ziemię w rozpatrywanym modelu. Jesteśmy bezpieczni.');
        return;
    else
        % Wyodrębnienie wyników
        x_m = Y(:,1);
        y_m = Y(:,2);
        z_m = Y(:,3);

        % Czas uderzenia w ziemię
        t_impact = t(end);
        disp(['Czas uderzenia w ziemię: ', num2str(t_impact), ' s']);
    end

    function [value, isterminal, direction] = ground_event(~, Y)
        value = Y(3);     % z=0
        isterminal = 1;   % zatrzymaj całkowanie
        direction = -1;   % wykrywaj przejście przez zero w dół
    end

    % Współrzędne meteorytu w chwili uderzenia w ziemię:
    x_ground = x_m(end);
    y_ground = y_m(end);

    % Odległość od (0,0) w płaszczyźnie xy:
    dist_ground = sqrt(x_ground^2 + y_ground^2);

    % Sprawdzamy, czy uderzenie nastąpi w obrębie koła o promieniu R:
    if dist_ground > R
        disp('Meteoryt uderzy w ziemię poza chronionym obszarem. Jesteśmy bezpieczni.');
        pause(0.5);
        zestrzel_meteoryt();
        return;
    else
        disp('UWAGA: Meteoryt uderzy w ziemię w chronionym obszarze!');
        fprintf('Czas do uderzenia: %.2f s\n', t_impact);
    end

    % ================================================
    % 2) Wyznaczenie parametrów rakiety (przechwycenie z oporem powietrza)
    % ================================================
    % Wysokość przechwytu (minimalna wysokość nad ziemią):
    z_min = 2000; % 2 km

    % Znajdź ostatni indeks gdzie z > z_min
    idx_intercept = find(z_m > z_min, 1, 'last');

    if isempty(idx_intercept)
        % Jeśli meteoryt nigdy nie był powyżej z_min, dostosuj wysokość
        z_min = max(z_m) - 100;
        idx_intercept = find(z_m > z_min, 1, 'last');
        fprintf('Dostosowano wysokość przechwytu do %.2f m\n', z_min);
    end

    t_przechwyt = t(idx_intercept);
    x_m_intercept = x_m(idx_intercept);
    y_m_intercept = y_m(idx_intercept);
    z_m_intercept = z_m(idx_intercept);

    % Oblicz wymagane składowe prędkości rakiety (rakieta startuje z (0,0,0))
    % Uwzględniamy ruch jednostajnie przyspieszony z grawitacją
    vx_r = x_m_intercept / t_przechwyt;
    vy_r = y_m_intercept / t_przechwyt;
    vz_r = (z_m_intercept + 0.5*g*t_przechwyt^2) / t_przechwyt;

    % Całkowita prędkość rakiety
    v_r = sqrt(vx_r^2 + vy_r^2 + vz_r^2);

    % Sprawdzenie maksymalnej prędkości (6.6 km/s dla DART)
    if v_r > 6600
        disp('UWAGA: Wymagana prędkość rakiety przekracza 6.6 km/s!');
        fprintf('Wymagana prędkość: %.2f m/s (%.2f km/s)\n', v_r, v_r/1000);
        disp('Program zatrzymany ze względów bezpieczeństwa.');
        return;
    end

    % Kąty rakiety względem osi (w radianach i stopniach)
    alpha_r = atan2(vy_r, vx_r);
    beta_r = atan2(vz_r, sqrt(vx_r^2 + vy_r^2));
    gamma_r = acos(vz_r / v_r);

    alpha_r_deg = rad2deg(alpha_r);
    beta_r_deg = rad2deg(beta_r);
    gamma_r_deg = rad2deg(gamma_r);

    % ======= WYŚWIETLANIE WYNIKÓW =======
    disp('=== WYNIKI PRZECHWYTU (z oporem powietrza) ===');
    fprintf('Czas przechwytu: t = %.2f s\n', t_przechwyt);
    fprintf('Pozycja przechwytu meteorytu: (%.2f, %.2f, %.2f) [m]\n',...
            x_m_intercept, y_m_intercept, z_m_intercept);
    fprintf('Pozycja uderzenia meteorytu: (%.2f, %.2f, 0) [m]\n',...
            x_ground, y_ground);
    fprintf('Niezbędna prędkość rakiety: v_r = %.2f m/s (%.2f km/s)\n', v_r, v_r/1000);
    fprintf('Kąty rakiety:\n');
    fprintf('   alpha_r (XY): %.2f°\n', alpha_r_deg);
    fprintf('   beta_r (nachylenie): %.2f°\n', beta_r_deg);
    fprintf('   gamma_r (Z): %.2f°\n', gamma_r_deg);

    % ==========================
    % 3) Wizualizacja trajektorii
    % ==========================

    % Dane meteorytu (z ode45) - tylko do momentu przechwytu
    x_m_vec = x_m(1:idx_intercept);
    y_m_vec = y_m(1:idx_intercept);
    z_m_vec = z_m(1:idx_intercept);
    t_m_vec = t(1:idx_intercept);

    % Symulacja rakiety - tylko do momentu przechwytu
    t_r_vec = linspace(0, t_przechwyt, idx_intercept)';
    x_r_vec = vx_r * t_r_vec;
    y_r_vec = vy_r * t_r_vec;
    z_r_vec = vz_r * t_r_vec - 0.5*g*t_r_vec.^2;

    % --------------------------
    % Wykres 1: Podgląd trajektorii
    % --------------------------
    figure('Name','Trajektorie 3D i 2D','Color','white', 'Position', [100 100 1200 500]);

    % Subplot 1: Widok 3D
    subplot(1,2,1);
    hold on;
    plot3(x_m_vec, y_m_vec, z_m_vec, 'r-', 'LineWidth', 2);
    plot3(x_r_vec, y_r_vec, z_r_vec, 'b--', 'LineWidth', 2);
    scatter3(x_m_intercept, y_m_intercept, z_m_intercept, 100, 'g', 'filled');
    scatter3(x_ground, y_ground, 0, 100, 'k', 'filled');
    xlabel('X [m]'); ylabel('Y [m]'); zlabel('Z [m]');
    legend('Meteoryt', 'Rakieta', 'Punkt przechwytu', 'Uderzenie w ziemię');
    grid on; axis tight;
    view(45, 30);
    title('Trajektoria 3D z oporem powietrza');

    % Subplot 2: Widok 2D (XY)
    subplot(1,2,2);
    hold on;
    plot(x_m_vec, y_m_vec, 'r-', 'LineWidth', 2);
    plot(x_r_vec, y_r_vec, 'b--', 'LineWidth', 2);
    scatter(x_m_intercept, y_m_intercept, 100, 'g', 'filled');
    scatter(x_ground, y_ground, 100, 'k', 'filled');
    theta = linspace(0, 2*pi, 100);
    plot(R*cos(theta), R*sin(theta), 'k--', 'LineWidth', 1);
    xlabel('X [m]'); ylabel('Y [m]');
    legend('Meteoryt', 'Rakieta', 'Przechwyt', 'Uderzenie', 'Obszar chroniony');
    grid on; axis equal;
    title('Rzut 2D (XY)');

    % --------------------------
    % Wykres 2: Animacja
    % --------------------------
    figure('Name','Animacja przechwytu','Color','white', 'Position', [200 200 800 600]);

    % Obliczanie granic osi
    x_min = min([min(x_m_vec); min(x_r_vec)]);
    x_max = max([max(x_m_vec); max(x_r_vec)]);
    y_min = min([min(y_m_vec); min(y_r_vec)]);
    y_max = max([max(y_m_vec); max(y_r_vec)]);
    z_max = max([max(z_m_vec); max(z_r_vec)]);

    margin = 1000; % metrów
    axis_limits = [x_min-margin, x_max+margin, y_min-margin, y_max+margin, 0, z_max+margin];

    % Inicjalizacja wykresu
    hold on;
    plot3(x_m_vec, y_m_vec, z_m_vec, 'r:', 'LineWidth', 0.5);
    plot3(x_r_vec, y_r_vec, z_r_vec, 'b:', 'LineWidth', 0.5);
    scatter3(x_m_intercept, y_m_intercept, z_m_intercept, 100, 'g', 'filled');
    scatter3(x_ground, y_ground, 0, 100, 'k', 'filled');

    h_meteor = plot3(x_m_vec(1), y_m_vec(1), z_m_vec(1), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    h_rocket = plot3(x_r_vec(1), y_r_vec(1), z_r_vec(1), 'bo', 'MarkerSize', 10, 'MarkerFaceColor', 'b');

    xlabel('X [m]'); ylabel('Y [m]'); zlabel('Z [m]');
    title('Animacja przechwytu meteorytu');
    legend('Meteoryt', 'Rakieta', 'Location', 'northeast');
    grid on;
    axis(axis_limits);
    view(45, 30);

    % Główna pętla animacji
    try
        animation_speed = 0.1; % szybsza animacja
        step = max(1, floor(length(t_m_vec)/100)); % pokazuj co 100 punktów dla płynności

        for i = 1:step:length(t_m_vec)
            if ~isvalid(h_meteor) || ~isvalid(h_rocket)
                disp('Animacja przerwana przez użytkownika.');
                break;
            end

            set(h_meteor, 'XData', x_m_vec(i), 'YData', y_m_vec(i), 'ZData', z_m_vec(i));
            set(h_rocket, 'XData', x_r_vec(i), 'YData', y_r_vec(i), 'ZData', z_r_vec(i));

            % Oblicz odległość między rakietą a meteorytem
            dist = sqrt((x_m_vec(i)-x_r_vec(i))^2 + (y_m_vec(i)-y_r_vec(i))^2 + (z_m_vec(i)-z_r_vec(i))^2);

            if dist < 100 % jeśli odległość < 100 m, uznajemy za przechwyt
                plot3(x_m_vec(i), y_m_vec(i), z_m_vec(i), 'y*', 'MarkerSize', 20, 'LineWidth', 2);
                text(x_m_vec(i), y_m_vec(i), z_m_vec(i), ' PRZECHWYT!', ...
                    'Color','y', 'FontWeight','bold', 'FontSize',12);
                break; % zakończ animację po przechwycie
            end

            drawnow;
            pause(animation_speed);
        end

        if isvalid(h_meteor) && isvalid(h_rocket)
            text(0.5, 0.9, 0, sprintf('Czas przechwytu: %.2f s', t_przechwyt), ...
                'Units','normalized', 'HorizontalAlignment','center', ...
                'FontSize',12, 'Color','k', 'BackgroundColor','w');
        end

    catch ME
        if strcmp(ME.identifier, 'MATLAB:class:InvalidHandle')
            disp('Okno animacji zostało zamknięte.');
        else
            rethrow(ME);
        end
    end
end