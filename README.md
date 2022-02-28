# nft.third.place-nft

<h2 href="random">Random generator</h2>

Данный контракт используется для получения случайного случайного nft из зараннее загруженной коллекции (В случае с nft.third.place возвращает случайный "кусочек" картины). 

Данный контракт работает по следующему принципу: деплоится контракт с зараннее указанным количеством элементов массива ("кусочков"). Далее необходимо вызвать метод fillParticlesArray. Данный метод был создан для возможности инициализировать массив с большим количеством элементов (Из-за ограничения газа в транзакции сразу не возможно инициализировать и заполнить весь массив). Данный метод добавляет по 100 элементов в динамический массив до того момента, пока массив не будет заполнен полностью. Только после полного заполнения массива с элементами можно будет получать случайный элемент из этого массива. 

Event:

```
    event RandomParticleWasGenerated(address recipient, uint256 particleId); 
```
Создается при вызове метода getRandomParticle, который возвращает случайный "кусочек" картины. <br><br>

Методы:

```
function fillParticlesArray() public onlyOwner checkBalance
```
Используется для обхода ограниченного количества газа в транзакции. Инициализирует массив с id кусочков по 100 за вызов метода. <br><br>

```
function getRandomParticle(address recipient) public onlyOwner checkBalance isActive returns(uint256 particleId)
```
Может быть вызван только после выполнения шага выше. Только после того, как будет полностью массив с id кусочков. Возвращает и удаляет случайный элемент из массива кусочков, а так же создает event RandomParticleWasGenerated. <br><br>

```
function getFreeParticles() public view returns (uint16[] particles)
```
Возвращает массив с оставшимися кусочками. <br><br>

<h2>Проверка случайного распределения кусочков</h2>

Для того, чтобы верифицировать процесс генерации и распределения кусочков картины необходимо использовать graphql по url - https://main.ton.dev/graphql

Для того, чтобы убедиться в том, что полученные кусочки действительно были распределены между их нынешними владельцами необходимо "распарсить" ивенты контракта. Контракт Random Generator доступен по адресу 0:... в mainnet.

Используем следующий код для получения ивентов с контракта:

```
query {
  messages(
  filter:{
    src: { eq: "0:88c6db909884913c48612109a858bfe4a457e55705a7cdec18aacbe26b863fc0" },
    msg_type: {
      eq: 2
    }
  }
  orderBy:{
    path:"created_lt"
    direction:DESC
  }
  )
  {
    body
  }
}
```

Полученные body из ивентов необходимо декодировать, используя следующую команду:

```
tonos-cli decode body --abi <.abi.json file> <msg.body>
```

Например, "распарсим" один ивент, его body:

```
te6ccgEBAQEASAAAi23pgeKAGBjObdlxnxvU133325YX/zyHPWAwtTfYXg+B2b2igm7gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAxA=
```
Декодируем его:

```
tonos-cli decode body --abi RandomGenerator.abi.json "te6ccgEBAQEASAAAi23pgeKAGBjObdlxnxvU133325YX/zyHPWAwtTfYXg+B2b2igm7gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAxA="

```
Получим следующий результат:

```
Config: default
Input arguments:
    body: te6ccgEBAQEASAAAi23pgeKAGBjObdlxnxvU133325YX/zyHPWAwtTfYXg+B2b2igm7gAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAxA=
     abi: RandomGenerator.abi.json
RandomParticleWasGenerated: {
  "recipient": "0:c0c6736ecb8cf8dea6bbefbedcb0bff9e439eb0185a9bec2f07c0ecded141377",
  "particleId": "0x0000000000000000000000000000000000000000000000000000000000000018"
}
```

Отсюда следует, что ивент называется RandomParticleWasGenerated и у него такие параметры: recipient и particleId. ParticleID - id "кусочка" картины в шестнадцатеричном формате. Таким образом можно проверить все ивенты и сопоставить с реальным распределением кусочков.
