!Разворачивание инфраструктуры с пушем проекта через Jenkins

! Terraform
В репозитории папка Terraform позволит развернуть инфраструктуру с нуля

1. Преднастройка перед использованием Terraform
1.1 Ручками создаем в yandex cloud сервисный аккаунт
1.2 Создаем авторизационный ключ для данного акка и кладем его в папку к main.tf в файл authorized_key.json
1.3 Файл main.tf, правишь cloud_id, а так же folder_id
1.4 Файл srv.tf, 52 стройка service_account_id, ставишь свой id сервисного
1.5 Файл srv.tf, 86 строка, меняешь расположение скрипта full.sh под себя
1.5 Файл k8s, 98 и 99 строка, тоже свой id
1.6 Файл cloud_config.yaml, генерируй ключ ssh-keygen -t ed25519 -0, вставляешь в ssh-authorized-keys
1.7 Контрольный выстрел через команды terraform init, terraform apply

Красавчик, наслаждайся бегущей строкой, как Нео в матрице)

! Jenkins
1. Настраиваем Jenkins
P.S. Бежишь по ip хоста:8080 с паролем от Jenkins, cat /var/lib/jenkins/secrets/initialAdminPassword, на перевес
1.1 Включаем переменные для пуша в docker hub
Manage Jenkins => System => Global properties => ставим галку для Global properties => Вводим две переменные DOCKER_USERNAME и DOCKER_PASSWORD (собственно, логин и пароль от docker hub)
1.2 Настраиваем уведомлялочку о завалившихся заданиях
Manage Jenkins => System => E-mail Notification => SMTP server = (smtp.gmail.com или smpt.mail.ru, чего ты там используешь то и вводи) => жмякаешь на Advanced, Use SMTP Authentication =>
=> User Name = вводишь почту => Password = тут уж нужно изловчиться и создать ключ приложения в настройках акка почты, уверен ты найдешь как это сделать, естественно ввести его в поле =>
=> жмякаешь на Use SSL => SMTP Port = 465 для gmail => Reply-To Address = снова почта => Test configuration by sending test e-mail и вуаля, настройка завершена

2. Для получения доступа к кластеру k8s для учетной записи Jenkins необходимо установить и пройти инициализацию в yc CLI
2.1 Из под четки Jenkins устанавливаем yc CLI, curl -sSL https://storage.yandexcloud.net/yandexcloud-yc/install.sh | bash
2.2 Проводим инициализацию yc init
2.3 Подключаемся к кластерку k8s (При открытии кластера в yandex cloud в правом верхнем углу будет вкладка c инструкцией "Подключиться")
P.S. https://yandex.cloud/ru/docs/cli/quickstart

3. Доступ к docker для jenkins, sudo chmod +x /usr/local/bin/docker-compose

4. Настраиваем pipeline
4.1 Имя pipeline django
4.2 Указываем репозиторий и Jenkinsfile
Репозитории: https://github.com/Crowmein/DevOps.git
Jenkinsfile: Project/Jenkinsfile

Запускаешь pipeline и радуешься жизни)

! Grafana
1. Гайдов хренова туча, ничего сложно, все необходимое уже установлено, ожидает только настройки через интерфейс, кроме k8s(
P.S. Логин и пароль "admin"
