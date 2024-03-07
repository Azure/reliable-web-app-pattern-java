# Redis

Redis can be used as a cache as well as a session store for a Spring Boot applications. As a cache, Redis is used to store the results of queries to the database. This reduces the number of queries to the database and improves performance. As a session store, Redis is used to store the session information for a web application.

## Pom.xml Dependencies

Add the following dependencies to the `pom.xml` file to configure Redis for the Contoso Fiber application.

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-cache</artifactId>
</dependency>
<dependency>
	<groupId>org.springframework.boot</groupId>
	<artifactId>spring-boot-starter-data-redis<artifactId>
</dependency>
<dependency>
	<groupId>org.springframework.session</groupId>
	<artifactId>spring-session-data-redis</artifactId>
</dependency>
```

## Caching with Redis - Spring Boot Configuration

To enable caching, we need to

1. Enable caching in the application with the `@EnableCaching` annotation
1. Configure the Redis cache manager
1. Configure the connection to Redis from the application
1. Use the @Cacheable annotation on the methods that we want to cache

### Enable Caching

In the main application `src/contoso-fiber/src/main/java/com/contoso/cams/CamsApplication.java`, add the `@EnableCaching` annotation to the `CamsApplication` class.

```java
@SpringBootApplication
@EnableCaching
public class ContosoFiberApplication {
    public static void main(String[] args) {
        SpringApplication.run(ContosoFiberApplication.class, args);
    }
}
```

### Configure Redis Cache Manager

We will configure the Cache Manager with a bean in the `src/contoso-fiber/src/main/java/com/contoso/cams/config/RedisCacheConfig.java` file.

```java
@Configuration
public class RedisCacheConfig {

    @Bean
    public RedisCacheConfiguration cacheConfiguration() {
        RedisCacheConfiguration config = RedisCacheConfiguration.defaultCacheConfig()
        .prefixCacheNameWith("com.contoso.cams.")
        .entryTtl(Duration.ofMinutes(60))
        .disableCachingNullValues()
        .serializeValuesWith(SerializationPair.fromSerializer(new GenericJackson2JsonRedisSerializer()));
        return config;
    }
    
    @Bean
    public RedisCacheManager cacheManager(RedisCacheConfiguration config, RedisConnectionFactory connectionFactory) {
        return RedisCacheManager.builder(connectionFactory)
            .cacheDefaults(config)
            .build();
    }
}
```

### Configure the Connection to Redis

Spring Data Redis properties come from the `application.properties` file. The following properties are used to configure the connection to Redis.

```properties
spring.data.redis.host=localhost
spring.data.redis.port=6379
```

### Use the @Cacheable Annotation

The `@Cacheable` annotation is used to cache the results of a method. The `@Cacheable` annotation will be used on the `getAccount` method in the `AccountService` class. The `@CachePut` annotation will be used on the `updateAccount` method in the `AccountService` class. You can use the `@CacheEvict` annotation to remove an item from the cache.

```java
package com.contoso.cams.account;

@Service
@CacheConfig(cacheNames={"accounts"})
public class AccountService {
    @CachePut(value="account-details", key="#accountDetail.accountId")
    public AccountDetail updateAccount(AccountDetail accountDetail) {
    }

    @CachePut(value="account-details", key="#id")
    public AccountDetail setActive(Long id, boolean isActive) {
    }

    @Cacheable(value="account-details", key="#id")
    public AccountDetail getAccountDetail(Long id) {
    }
}
```

## Session Management

In Contoso Fiber CAMS, Redis is used to store Spring Session that is used to manage the session information for a web application. In a Spring Boot application, Spring Session is configured with the `spring-session-data-redis` dependency in the `pom.xml` file.

```xml
<dependency>
    <groupId>org.springframework.session</groupId>
    <artifactId>spring-session-data-redis</artifactId>
</dependency>
```

### Spring Session Configuration

To enable Spring Session, add the following properties to the `application.properties` file.

```properties
# Spring Session to leverage Redis to back a web application’s HttpSession
spring.session.redis.flush-mode=on-save
spring.session.redis.namespace=spring:session
```

## Running the Application

Now that we have configured the application to use Redis, we can run the application and see the results in Redis.  Click on an account and then go to the Redis CLI to see the results. Our keys have the prefix `com.contoso.cams`.

```shell
docker exec -it contoso_fiber_redis bash
root@redis:/data# redis-cli

127.0.0.1:6379> keys *
1) "com.contoso.cams.account-details::1"
2) "spring:session:sessions:05625b53-9a7e-4a01-bd97-8995fc902060"
```

Get the account details from Redis.

```shell
127.0.0.1:6379> get com.contoso.cams.account-details::1
"{\"@class\":\"com.contoso.cams.account.AccountDetail\",\"accountId\":1,\"customerId\":1,\"address\":\"123 Main St.\",\"city\":\"Burlington\",\"customerFirstName\":\"Nick\",\"customerLastName\":\"Dalalelis\",\"customerEmail\":\"ndalalelis@microsoft.com\",\"customerPhoneNumber\":\"617-528-5544\",\"selectedServicePlanId\":1,\"active\":false,\"supportCases\":[\"java.util.ArrayList\",[]]}"
```
